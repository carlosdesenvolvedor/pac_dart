import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/simulacao_historia.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/encenador_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';

/// 📺 O modelo das historinhas das lições (plano §5, §6.4, §16): parse estrito/tolerante, âncoras com o texto
/// do currículo, um caso negativo por regra L-* da §5.3 e a extração do `validarCenaBase` do Turismo com as
/// mensagens de sempre.

/// O exemplo do plano (§5.4), igual a `$SP/historias_licoes/exemplo_licao.json`.
const exemploLicao = r'''
{
  "versao": 1,
  "trilha": "primeiro-contato",
  "arco": "Primeira semana com o time: a 1ª chamada, a visita ao escritório de Chicago e o 1º 'até amanhã' sem medo.",
  "licoes": {
    "primeiro-contato.oi-tudo-bem": {
      "titulo": { "en": "The first call", "pt": "A primeira chamada" },
      "cenas": [
        {
          "cenario": "videochamada", "hora": "dia", "clima": [],
          "elenco": [
            { "quem": "voce", "pos": "centroEsquerda", "segura": "cafe", "emocao": "nervoso" },
            { "quem": "mike", "pos": "centroDireita", "emocao": "feliz" },
            { "quem": "ana", "pos": "direita", "visivel": false }
          ],
          "objetos": [],
          "passos": [
            { "frase": "f-ceea0d", "acao": "acena", "emocao": "feliz", "camera": "medio" },
            { "frase": "f-138833", "acao": "acena", "emocao": "radiante" },
            { "frase": "f-cddcb0", "acao": "concorda", "emocao": "feliz",
              "reacoes": [ { "quem": "mike", "emocao": "feliz" } ] },
            { "frase": "f-0f3970", "acao": "concorda" },
            { "mudo": true, "quem": "ana", "acao": "entra", "emocao": "feliz" },
            { "frase": "f-34d001", "acao": "acena", "alvo": "ana", "camera": "geral" },
            { "frase": "f-e15dec", "acao": "acena", "emocao": "feliz" },
            { "frase": "f-3a3e3a", "emocao": "feliz" },
            { "frase": "f-f9d8da", "acao": "aponta", "alvo": "mike",
              "reacoes": [ { "quem": "mike", "acao": "concorda" } ] }
          ]
        }
      ]
    }
  }
}
''';

const _oiId = 'primeiro-contato.oi-tudo-bem';
const _placaId = 'primeiro-contato.a-placa';

/// Os 8 trechos reais de `primeiro-contato.oi-tudo-bem` (assets/ingles/curriculo.json, 22/out/2026).
const _trechosOi = [
  Trecho(id: 'f-ceea0d', quem: 'voce', cod: 'Good morning, Mike!', dica: 'Bom dia, Mike!', out: '', imagem: '☀️👋'),
  Trecho(id: 'f-138833', quem: 'mike', cod: "Hi, Carlos! How's it going?", dica: 'Oi, Carlos! Tudo bem?', out: '', imagem: '🙂❓'),
  Trecho(id: 'f-cddcb0', quem: 'voce', cod: 'Pretty good, thanks. How about you?', dica: 'Tudo certo, obrigado. E você?', out: '', imagem: '👍🔁'),
  Trecho(id: 'f-0f3970', quem: 'mike', cod: "I'm good, thanks.", dica: 'Tudo bem, obrigado.', out: '', imagem: '😊👍'),
  Trecho(id: 'f-34d001', quem: 'voce', cod: 'Hi, Ana! Good afternoon!', dica: 'Oi, Ana! <b>Boa tarde</b>!', out: '', imagem: '🌤️👋'),
  Trecho(id: 'f-e15dec', quem: 'ana', cod: "How's it going, Carlos?", dica: 'Tudo bem, Carlos?', out: '', imagem: '👩‍🎨❓'),
  Trecho(id: 'f-3a3e3a', quem: 'voce', cod: "I'm good, thanks. How about you?", dica: 'Tudo bem, obrigado. E você?', out: '', imagem: '🙂↩️'),
  Trecho(id: 'f-f9d8da', quem: 'ana', cod: 'Good, thanks. How about you, Mike?', dica: 'Bem, obrigada. E você, Mike?', out: '', imagem: '👉👨‍💻❓'),
];

const _licaoOi = Licao(id: _oiId, nome: 'Oi, tudo bem?', emoji: '👋', trechos: _trechosOi);

/// Uma lição inventada com uma frase de placa (quem 'placa' → narrador).
const _licaoPlaca = Licao(id: _placaId, nome: 'A placa', emoji: '🪧', trechos: [
  Trecho(id: 'f-p1', quem: 'placa', cod: 'Exit.', dica: 'Saída.', out: ''),
  Trecho(id: 'f-p2', quem: 'voce', cod: 'There it is!', dica: 'Ali está!', out: ''),
]);

const _trilha = Trilha(
  nivel: 'Primeiro contato',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: [_licaoOi, _licaoPlaca],
);

Map<String, dynamic> _exemplo() => jsonDecode(exemploLicao) as Map<String, dynamic>;

Map<String, dynamic> _licaoJ(Map<String, dynamic> j, [String id = _oiId]) =>
    (j['licoes'] as Map<String, dynamic>)[id] as Map<String, dynamic>;

Map<String, dynamic> _cena(Map<String, dynamic> j, [int i = 0]) => (_licaoJ(j)['cenas'] as List)[i] as Map<String, dynamic>;

List<dynamic> _passos(Map<String, dynamic> j, [int i = 0]) => _cena(j, i)['passos'] as List;

List<dynamic> _elenco(Map<String, dynamic> j, [int i = 0]) => _cena(j, i)['elenco'] as List;

HistoriasDaTrilha _parse(Map<String, dynamic> j) => HistoriasDaTrilha.fromJson(j, trilha: _trilha);

/// Parse estrito + validar a lição do exemplo depois de [mexer].
List<String> _erros(void Function(Map<String, dynamic> j) mexer) {
  final j = _exemplo();
  mexer(j);
  final h = _parse(j);
  return validarHistoriaLicao(h.licoes[_oiId]!, _licaoOi);
}

void _temErro(List<String> erros, String trecho) =>
    expect(erros.any((e) => e.contains(trecho)), isTrue, reason: 'esperava "$trecho" em $erros');

void _parseFalha(void Function(Map<String, dynamic> j) mexer, String trecho) {
  final j = _exemplo();
  mexer(j);
  expect(() => _parse(j), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(trecho))));
}

void main() {
  group('funções e tabelas', () {
    test('quemNoPalco, nivelDaEtapa, slugDaLicao', () {
      expect(quemNoPalco(''), narrador);
      expect(quemNoPalco('placa'), narrador);
      expect(quemNoPalco('narradora'), narrador);
      expect(quemNoPalco('atendente'), 'atendente');
      expect(nivelDaEtapa('A1 · Fundação'), NivelIngles.a1);
      expect(nivelDaEtapa('A2 · Dia a dia'), NivelIngles.a2);
      expect(nivelDaEtapa('B1 · Independência'), NivelIngles.b1);
      expect(nivelDaEtapa('B2 · Desenvoltura'), NivelIngles.b2);
      expect(nivelDaEtapa('C1 · Domínio'), NivelIngles.b2);
      expect(nivelDaEtapa('DEV · Inglês profissional de dev'), NivelIngles.b2);
      expect(slugDaLicao(_oiId), 'primeiro-contato');
      expect(slugDaLicao('sem-ponto'), 'sem-ponto');
    });

    test('elenco das lições, figurantes conhecidos e o que é só do Turismo', () {
      expect(elencoDasLicoes, hasLength(9));
      expect(elencoDasLicoes.intersection({'max', 'kim'}), isEmpty);
      expect(elencoDasLicoes.difference(personagensHistoria), isEmpty);
      expect(figurantesConhecidos, hasLength(42));
      expect(figurantesConhecidos.intersection(elencoDasLicoes), isEmpty);
      expect(maxFigurantesMudos, 2);
      expect(cenariosSoDoTurismo, hasLength(9));
      expect(cenariosSoDoTurismo.intersection({
        CenarioHistoria.videochamada,
        CenarioHistoria.escritorio,
        CenarioHistoria.casa,
        CenarioHistoria.restaurante,
        CenarioHistoria.loja,
      }), isEmpty);
      expect(propsSoDoTurismo, hasLength(9));
      expect(acoesQueDeslocam, hasLength(6));
    });

    test('os 5 cenários e as 4 props novas entraram no fim dos enums e os cenários são interiores', () {
      // a 2ª leva (pedidos de arte dos lotes) entrou DEPOIS destes: o teste confere a fatia de cada leva, sem
      // mexer na ordem de antes (o Turismo depende dos índices)
      expect(CenarioHistoria.values.sublist(25, 30).map((c) => c.name),
          ['videochamada', 'escritorio', 'casa', 'restaurante', 'loja']);
      expect(PropHistoria.values.sublist(24, 28).map((p) => p.name), ['notebook', 'prato', 'sacola', 'documento']);
      // a 3ª leva tem o `quintal` (exterior, conferido em historia_cenarios_licao3_test): aqui ficam as 2 primeiras
      // levas, todas interiores (25..33)
      for (final c in CenarioHistoria.values.sublist(25, 33)) {
        expect(interioresHistoria.contains(c), isTrue, reason: c.name);
        expect(horasPermitidas(c), HoraHistoria.values.toSet(), reason: c.name);
      }
      expect(personagensHistoria, hasLength(11), reason: 'o elenco do Turismo não muda');
    });
  });

  group('parse do exemplo (§5.4)', () {
    test('estrito: lê a lição e puxa quem/en/pt do currículo nas âncoras', () {
      final t = _parse(_exemplo());
      expect(t.versao, 1);
      expect(t.trilha, 'primeiro-contato');
      expect(t.arco, startsWith('Primeira semana'));
      final h = t.licoes[_oiId]!;
      expect(h.autoral, isTrue);
      expect(h.nivel, NivelIngles.a1);
      expect(h.titulo!.en, 'The first call');
      expect(h.titulo!.pt, 'A primeira chamada');
      expect(h.cenas, hasLength(1));
      final cena = h.cenas.single;
      expect(cena.cenario, CenarioHistoria.videochamada);
      expect(cena.elenco.map((a) => a.quem), ['voce', 'mike', 'ana']);
      expect(cena.elenco[0].segura, PropHistoria.cafe);
      expect(cena.elenco[0].emocao, Expressao.nervoso);
      expect(cena.elenco[2].visivel, isFalse);
      expect(cena.falas, hasLength(9));
      final f0 = cena.falas[0];
      expect(f0.quem, 'voce');
      expect(f0.en, 'Good morning, Mike!');
      expect(f0.pt, 'Bom dia, Mike!');
      expect(f0.acao, AcaoAtor.acena);
      expect(f0.camera, CameraHistoria.medio);
      // o pt é a dica plana (sem <b>)
      expect(cena.falas[5].pt, 'Oi, Ana! Boa tarde!');
      expect(cena.falas[5].alvo, 'ana');
      final mudo = cena.falas[4];
      expect(mudo.mudo, isTrue);
      expect(mudo.quem, 'ana');
      expect(mudo.acao, AcaoAtor.entra);
      expect(cena.falas[8].quem, 'ana');
      expect(cena.falas[8].reacoes.single.acao, AcaoAtor.concorda);
    });

    test('âncoras: Trecho.id → (cena, passo), pulando o mudo', () {
      final h = _parse(_exemplo()).licoes[_oiId]!;
      expect(h.ancoras, {
        'f-ceea0d': (0, 0),
        'f-138833': (0, 1),
        'f-cddcb0': (0, 2),
        'f-0f3970': (0, 3),
        'f-34d001': (0, 5),
        'f-e15dec': (0, 6),
        'f-3a3e3a': (0, 7),
        'f-f9d8da': (0, 8),
      });
    });

    test('validarHistoriaLicao fica vazio para o exemplo; a trilha avisa a lição sem história', () {
      final t = _parse(_exemplo());
      expect(validarHistoriaLicao(t.licoes[_oiId]!, _licaoOi), isEmpty);
      final avisos = <String>[];
      expect(validarHistoriasDaTrilha(t, _trilha, avisos: avisos), isEmpty);
      expect(avisos, ['$_placaId: sem história (trilha incompleta)']);
    });

    test('a linha do tempo da simulação chega com a Ana visível e todos felizes', () {
      final cena = _parse(_exemplo()).licoes[_oiId]!.cenas.single;
      final fim = SimulacaoCena.linhaDoTempo(cena).last;
      expect(fim.atores['ana']!.visivel, isTrue);
      expect(fim.atores['voce']!.emocao, Expressao.feliz);
    });

    test('uma frase de placa vira narrador e valida', () {
      final j = {
        'versao': 1,
        'trilha': 'primeiro-contato',
        'licoes': {
          _placaId: {
            'titulo': {'en': 'The sign', 'pt': 'A placa'},
            'cenas': [
              {
                'cenario': 'aeroporto',
                'hora': 'dia',
                'elenco': [
                  {'quem': 'voce', 'pos': 'centro'},
                ],
                'passos': [
                  {'frase': 'f-p1'},
                  {'frase': 'f-p2', 'acao': 'aponta'},
                ],
              },
            ],
          },
        },
      };
      final h = HistoriasDaTrilha.fromJson(j, trilha: _trilha).licoes[_placaId]!;
      expect(h.cenas.single.falas.first.quem, narrador);
      expect(h.cenas.single.falas.first.en, 'Exit.');
      expect(validarHistoriaLicao(h, _licaoPlaca), isEmpty);
    });
  });

  group('parse estrito × tolerante', () {
    test('estrito: chave desconhecida, falas no lugar de passos, enum inválido com o lugar exato', () {
      _parseFalha((j) => _licaoJ(j)['resumo'] = 'x', "$_oiId: chave 'resumo' desconhecida");
      _parseFalha((j) {
        final c = _cena(j);
        c['falas'] = c.remove('passos');
      }, "$_oiId cena[0]: chave 'falas' desconhecida (use 'passos', não 'falas')");
      _parseFalha((j) => (_passos(j)[2] as Map)['emocao'] = 'happy', "$_oiId cena[0] passo 3: emocao 'happy' inválida");
      _parseFalha((j) => (_elenco(j)[1] as Map)['pos'] = 'meio', "$_oiId cena[0] elenco[1]: pos 'meio' inválida");
      _parseFalha((j) => _cena(j)['cenario'] = 'lugar', "$_oiId cena[0]: cenario 'lugar' inválido");
    });

    test('L-arquivo no parse: versão, lição de fora da trilha, sem licoes', () {
      _parseFalha((j) => j['versao'] = 2, 'arquivo: versao 2 (esperava 1)');
      _parseFalha((j) => (j['licoes'] as Map)['outra-trilha.x'] = _licaoJ(j),
          "outra-trilha.x: não é lição da trilha 'primeiro-contato'");
      _parseFalha((j) => j.remove('licoes'), "arquivo 'licoes': esperava um objeto JSON");
    });

    test('tolerante: descarta só a lição ruim (parse ou validação) e ignora chave desconhecida', () {
      final j = _exemplo();
      j['extra'] = true;
      _licaoJ(j)['resumo'] = 'ignorado';
      (j['licoes'] as Map)[_placaId] = {
        'titulo': {'en': 'The sign', 'pt': 'A placa'},
        'cenas': [
          {
            'cenario': 'aeroporto',
            'hora': 'dia',
            'elenco': [
              {'quem': 'voce', 'pos': 'centro'},
            ],
            'passos': [
              {'frase': 'f-nao-existe'},
            ],
          },
        ],
      };
      final avisos = <String>[];
      final t = HistoriasDaTrilha.fromJson(j, trilha: _trilha, estrito: false, aviso: avisos.add);
      expect(t.licoes.keys, [_oiId]);
      expect(avisos, hasLength(1));
      expect(avisos.single, contains("frase 'f-nao-existe' desconhecida"));

      // uma lição que parseia mas não valida (frase faltando) também cai na automática
      final k = _exemplo();
      _passos(k).removeLast();
      final avisos2 = <String>[];
      final t2 = HistoriasDaTrilha.fromJson(k, trilha: _trilha, estrito: false, aviso: avisos2.add);
      expect(t2.licoes, isEmpty);
      expect(avisos2.single, contains('frases faltando: f-f9d8da'));
      // enum de enfeite desconhecido → padrão no tolerante
      final m = _exemplo();
      (_passos(m)[3] as Map)['emocao'] = 'happy';
      final t3 = HistoriasDaTrilha.fromJson(m, trilha: _trilha, estrito: false);
      expect(t3.licoes[_oiId]!.cenas.single.falas[3].emocao, emocaoPadrao);
    });
  });

  group('validação — um caso negativo por regra (§5.3)', () {
    test('L-arquivo', () {
      final t = _parse(_exemplo());
      final outra = HistoriasDaTrilha(versao: 2, trilha: 'outra', arco: 'x' * 301, licoes: t.licoes);
      final erros = validarHistoriasDaTrilha(outra, _trilha);
      _temErro(erros, 'arquivo: versao tem de ser 1');
      _temErro(erros, "arquivo: trilha 'outra' diferente da trilha 'primeiro-contato'");
      _temErro(erros, 'arquivo: arco com 301 caracteres (máx. 300)');
      final fora = HistoriasDaTrilha(versao: 1, trilha: 'primeiro-contato', licoes: {'x.y': t.licoes[_oiId]!});
      _temErro(validarHistoriasDaTrilha(fora, _trilha), "x.y: não é lição da trilha 'primeiro-contato'");
    });

    test('L-título', () {
      _temErro(_erros((j) => _licaoJ(j).remove('titulo')), '$_oiId: titulo ausente (obrigatório na história autoral)');
      _temErro(_erros((j) => _licaoJ(j)['titulo'] = {'en': 'One two three four five six seven', 'pt': 'x'}),
          '$_oiId: titulo.en tem de ter de 1 a 6 palavras, só ASCII');
      _temErro(_erros((j) => _licaoJ(j)['titulo'] = {'en': 'Café time', 'pt': 'x'}), 'só ASCII');
      _temErro(_erros((j) => _licaoJ(j)['titulo'] = {'en': 'The Zoom call', 'pt': 'A chamada'}),
          "$_oiId: termo proibido 'zoom' no título");
      _temErro(_erros((j) => _licaoJ(j)['titulo'] = {'en': 'The first call', 'pt': ' '}), '$_oiId: titulo.pt vazio');
    });

    test('L-cobertura: faltando, repetida, fora da ordem, desconhecida', () {
      _temErro(_erros((j) => _passos(j).removeLast()), '$_oiId: frases faltando: f-f9d8da');
      _temErro(_erros((j) => _passos(j).add({'frase': 'f-ceea0d'})), '$_oiId: frases repetidas: f-ceea0d');
      _temErro(_erros((j) {
        final p = _passos(j);
        final a = p[0];
        p[0] = p[2];
        p[2] = a;
      }), '$_oiId: frases fora da ordem da lição');
      _parseFalha((j) => (_passos(j)[0] as Map)['frase'] = 'f-zzzzzz', "$_oiId cena[0] passo 1: frase 'f-zzzzzz' desconhecida");
    });

    test('L-âncora: campos proibidos, quem trocado e deslocamento', () {
      for (final campo in ['en', 'pt', 'pt_f', 'mudo']) {
        _parseFalha((j) => (_passos(j)[1] as Map)[campo] = campo == 'mudo' ? false : 'x.',
            "$_oiId cena[0] passo 2: âncora não leva '$campo' (o texto vem do currículo)");
      }
      _parseFalha((j) => (_passos(j)[1] as Map)['quem'] = 'ana', "$_oiId cena[0] passo 2: quem 'ana' não bate com o da frase ('mike')");
      // quem igual ao da frase é aceito
      expect(_erros((j) => (_passos(j)[1] as Map)['quem'] = 'mike'), isEmpty);
      _temErro(_erros((j) => (_passos(j)[0] as Map)
        ..['acao'] = 'anda'
        ..['para'] = 'centro'), "$_oiId cena[0] passo 1: acao 'anda' desloca: vai num passo mudo antes ou depois");
    });

    test('L-ligação: fala com texto sem frase', () {
      _parseFalha((j) => _passos(j).insert(1, {'quem': 'voce', 'en': 'Hi.', 'pt': 'Oi.'}),
          "$_oiId cena[0] passo 2: fala sem 'frase': falas de ligação são só atuadas (mudo)");
    });

    test('L-cenas: 1 a 2 cenas, âncora em cada cena, mudos na história', () {
      // 3 cenas (cada uma com uma parte das frases, na ordem)
      _temErro(_erros((j) {
        final c = _cena(j);
        final passos = List.of(c['passos'] as List);
        Map<String, dynamic> parte(List<dynamic> ps) => {...c, 'elenco': jsonDecode(jsonEncode(c['elenco'])), 'passos': ps};
        _licaoJ(j)['cenas'] = [parte(passos.sublist(0, 2)), parte(passos.sublist(2, 4)), parte(passos.sublist(4))];
      }), '$_oiId: de 1 a 2 cenas');
      // uma cena só de mudo
      _temErro(_erros((j) {
        final c = _cena(j);
        _licaoJ(j)['cenas'] = [
          c,
          {
            ...c,
            'elenco': [
              {'quem': 'voce', 'pos': 'centro'},
            ],
            'passos': [
              {'mudo': true, 'quem': 'voce', 'acao': 'acena'},
            ],
          },
        ];
      }), '$_oiId cena[1]: cena sem nenhuma âncora (frase)');
      // 5 mudos na história (3 numa cena, 2 na outra; nunca 3 seguidos)
      _temErro(_erros((j) {
        final p = _passos(j);
        for (final i in [1, 3]) {
          p.insert(i, {'mudo': true, 'quem': 'voce', 'acao': 'acena'});
        }
        final c = _cena(j);
        final passos = List.of(c['passos'] as List);
        _licaoJ(j)['cenas'] = [
          {...c, 'passos': passos.sublist(0, 7)},
          {
            ...c,
            'elenco': [
              {'quem': 'voce', 'pos': 'centroEsquerda'},
              {'quem': 'mike', 'pos': 'centroDireita'},
              {'quem': 'ana', 'pos': 'direita'},
            ],
            'passos': [
              {'mudo': true, 'quem': 'voce', 'acao': 'acena'},
              ...passos.sublist(7, 9),
              {'mudo': true, 'quem': 'mike', 'acao': 'acena'},
              ...passos.sublist(9),
            ],
          },
        ];
      }), '$_oiId: 5 passos mudos (máx. 4 na história)');
      // 4 mudos numa cena: a regra do Turismo (máx. 3 por cena) vale
      _temErro(_erros((j) {
        final p = _passos(j);
        for (final i in [1, 3, 5]) {
          p.insert(i, {'mudo': true, 'quem': 'voce', 'acao': 'acena'});
        }
      }), '$_oiId cena[0]: 4 passos mudos (máx. 3)');
    });

    test('L-cenário/props', () {
      _temErro(_erros((j) => _cena(j)['cenario'] = 'autodromo'), "$_oiId cena[0]: cenário 'autodromo' é só do Turismo");
      _temErro(_erros((j) => (_cena(j)['objetos'] as List).add({'prop': 'trofeu', 'pos': 'centro'})),
          "$_oiId cena[0]: prop 'trofeu' é só do Turismo");
      _temErro(_erros((j) => (_passos(j)[0] as Map)['segura'] = 'capacete'),
          "$_oiId cena[0] passo 1: prop 'capacete' é só do Turismo");
      _temErro(_erros((j) => (_elenco(j)[0] as Map)['noCarro'] = true), '$_oiId cena[0]: noCarro é só do Turismo');
    });

    test('L-elenco: Max/Kim, gente desconhecida e mais de 2 figurantes mudos', () {
      _temErro(_erros((j) => _elenco(j).add({'quem': 'max', 'pos': 'esquerda'})), "$_oiId cena[0]: 'max' é só do Turismo");
      _temErro(_erros((j) => _elenco(j).add({'quem': 'zelador', 'pos': 'esquerda'})),
          "$_oiId cena[0]: 'zelador' não é do elenco das lições nem figurante conhecido");
      // até 2 figurantes mudos: ok
      expect(
          _erros((j) => _elenco(j)
            ..add({'quem': 'recepcionista', 'pos': 'esquerda'})
            ..add({'quem': 'garcom', 'pos': 'centro'})),
          isEmpty);
      _temErro(
          _erros((j) => _elenco(j)
            ..add({'quem': 'recepcionista', 'pos': 'esquerda'})
            ..add({'quem': 'garcom', 'pos': 'centro'})
            ..add({'quem': 'oficial', 'remoto': 'celular'})),
          '$_oiId: 3 figurantes mudos (máx. 2): garcom, oficial, recepcionista');
    });

    test('L-base: a simulação do Turismo com o prefixo da lição', () {
      _temErro(_erros((j) => _cena(j)['clima'] = ['neblina']),
          "$_oiId cena[0]: clima 'neblina' não combina com 'videochamada'/'dia'");
      _temErro(_erros((j) => (_passos(j)[0] as Map)['alvo'] = 'sarah'),
          "$_oiId cena[0] passo 1: alvo 'sarah' não é ator presente nem objeto visível");
      _temErro(_erros((j) => (_elenco(j)[1] as Map)['pos'] = 'centroEsquerda'),
          "$_oiId cena[0]: posição inicial 'centroEsquerda' repetida");
      _temErro(_erros((j) {
        final p = _passos(j);
        for (var i = 0; i < 3; i++) {
          p.insert(1, {'mudo': true, 'quem': 'voce', 'acao': 'acena'});
        }
      }), '$_oiId cena[0] passo 4: mais de 2 passos mudos seguidos');
      // a Ana fala sem ter entrado (o mudo `entra` sumiu)
      _temErro(_erros((j) => _passos(j).removeAt(4)), "$_oiId cena[0] passo 6: 'ana' não está visível (use acao entra)");
    });

    test('L-narrador e a fala com texto que não é de nenhuma frase (montadas no código)', () {
      final cena = CenaHistoria(
        cenario: CenarioHistoria.casa,
        hora: HoraHistoria.dia,
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
          AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
          AtorEmCena(quem: 'ana', pos: PosicaoPalco.direita),
        ],
        falas: [
          const FalaHistoria(quem: narrador, en: 'Good morning, Mike!', pt: 'Bom dia, Mike!'),
          for (final t in _trechosOi.skip(1)) FalaHistoria(quem: t.quem, en: t.cod, pt: t.dicaPlana),
          const FalaHistoria(quem: 'voce', en: 'Bye.', pt: 'Tchau.'),
        ],
      );
      final h = HistoriaLicao.daLicao(_licaoOi, [cena], nivel: NivelIngles.a1, autoral: false);
      final erros = validarHistoriaLicao(h, _licaoOi);
      _temErro(erros, '$_oiId cena[0] passo 1: narrador só onde a frase é de placa');
      _temErro(erros, "$_oiId cena[0] passo 9: fala sem 'frase': falas de ligação são só atuadas (mudo)");
      // a automática não precisa de título
      expect(erros.any((e) => e.contains('titulo')), isFalse);
    });
  });

  group('HistoriaLicao.daLicao', () {
    test('monta as âncoras pelas falas com texto na ordem (pulando os mudos, através das cenas)', () {
      CenaHistoria cena(List<FalaHistoria> falas) => CenaHistoria(
            cenario: CenarioHistoria.casa,
            hora: HoraHistoria.dia,
            elenco: const [
              AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
              AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
              AtorEmCena(quem: 'ana', pos: PosicaoPalco.direita),
            ],
            falas: falas,
          );
      final falas = [for (final t in _trechosOi) FalaHistoria(quem: t.quem, en: t.cod, pt: t.dicaPlana)];
      const mudo = FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.acena);
      final h = HistoriaLicao.daLicao(
        _licaoOi,
        [cena([...falas.sublist(0, 3), mudo, falas[3]]), cena(falas.sublist(4))],
        nivel: NivelIngles.a1,
        titulo: const TextoBilingue('Hello', 'Olá'),
        autoral: true,
      );
      expect(h.licaoId, _oiId);
      expect(h.autoral, isTrue);
      expect(h.ancoras['f-ceea0d'], (0, 0));
      expect(h.ancoras['f-cddcb0'], (0, 2));
      expect(h.ancoras['f-0f3970'], (0, 4));
      expect(h.ancoras['f-34d001'], (1, 0));
      expect(h.ancoras['f-f9d8da'], (1, 3));
      expect(h.ancoras, hasLength(8));
      expect(validarHistoriaLicao(h, _licaoOi), isEmpty);
    });

    test('o encenador da Phase 0 já devolve uma história válida (inclusive com placa)', () {
      for (final l in [_licaoOi, _licaoPlaca]) {
        final h = EncenadorLicao.encenar(l, etapa: _trilha.etapa);
        expect(h.autoral, isFalse);
        expect(h.titulo, isNull);
        expect(h.ancoras, hasLength(l.trechos.length));
        expect(validarHistoriaLicao(h, l), isEmpty, reason: l.id);
      }
      // a tabela manual vale (e um cenário só do Turismo é ignorado)
      final loja = EncenadorLicao.encenar(_licaoOi,
          etapa: _trilha.etapa, manual: EncenacaoManual.fromJson({'cenario': 'loja', 'hora': 'noite', 'x': 1}));
      expect(loja.cenas.single.cenario, CenarioHistoria.loja);
      expect(loja.cenas.single.hora, HoraHistoria.noite);
      final turismo =
          EncenadorLicao.encenar(_licaoOi, etapa: _trilha.etapa, manual: const EncenacaoManual(cenario: CenarioHistoria.lua));
      expect(validarHistoriaLicao(turismo, _licaoOi), isEmpty);
    });

    test('EncenacaoManual.fromJson é tolerante', () {
      final m = EncenacaoManual.fromJson({
        'cenario': 'nao-existe',
        'hora': 'tarde',
        'remotos': {'ana': 'celular', 'ben': 'pombo'},
        'entram': ['sarah', 3],
        'mudos': ['recepcionista'],
      });
      expect(m.cenario, isNull);
      expect(m.hora, HoraHistoria.tarde);
      expect(m.remotos, {'ana': ViaRemota.celular});
      expect(m.entram, {'sarah'});
      expect(m.mudos, {'recepcionista'});
    });
  });

  group('validarCenaBase (extraída do Turismo, mensagens idênticas)', () {
    const elenco = [
      AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
      AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
    ];

    test('as mensagens de sempre com personagens: personagensHistoria', () {
      final erros = <String>[];
      validarCenaBase(
        'cap 3 intro[0]',
        const CenaHistoria(
          cenario: CenarioHistoria.lua,
          hora: HoraHistoria.dia,
          elenco: [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro),
            AtorEmCena(quem: 'zed', pos: PosicaoPalco.esquerda),
            AtorEmCena(quem: narrador, pos: PosicaoPalco.direita),
            AtorEmCena(quem: 'mike', pos: PosicaoPalco.centro),
          ],
          falas: [
            FalaHistoria(quem: 'voce', en: 'Hi', pt: 'Oi'),
            FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.acena),
            FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.pula),
            FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.palmas),
            FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.concorda),
          ],
        ),
        NivelIngles.a1,
        erros,
        personagens: personagensHistoria,
      );
      // o texto exato de antes da extração
      for (final m in [
        "cap 3 intro[0]: hora 'dia' não combina com 'lua'",
        "cap 3 intro[0]: personagem 'zed' desconhecido",
        'cap 3 intro[0]: o narrador não entra no elenco',
        "cap 3 intro[0]: posição inicial 'centro' repetida",
        "cap 3 intro[0] fala 1: en tem de terminar com . ! ? ou … ('Hi')",
        'cap 3 intro[0] fala 4: mais de 2 passos mudos seguidos',
        'cap 3 intro[0]: 4 passos mudos (máx. 3)',
      ]) {
        expect(erros, contains(m));
      }
    });

    test('devolve a linha do tempo; cena sem falas; porFala só nos passos com texto, depois do texto', () {
      final ordem = <String>[];
      final erros = _ErrosAnotados(ordem);
      final linha = validarCenaBase(
        'c',
        const CenaHistoria(
          cenario: CenarioHistoria.cidade,
          hora: HoraHistoria.dia,
          elenco: elenco,
          falas: [
            FalaHistoria(quem: 'voce', en: 'Hello', pt: 'Olá'),
            FalaHistoria(quem: 'mike', mudo: true, acao: AcaoAtor.acena),
            FalaHistoria(quem: 'mike', en: 'Hi!', pt: 'Oi!'),
          ],
        ),
        NivelIngles.a1,
        erros,
        personagens: personagensHistoria,
        porFala: (fc, f) => ordem.add('porFala $fc ${f.quem}'),
      );
      expect(linha, hasLength(4));
      expect(ordem, [
        "erro c fala 1: en tem de terminar com . ! ? ou … ('Hello')",
        'porFala c fala 1 voce',
        'porFala c fala 3 mike',
      ]);
      final vazia = <String>[];
      expect(
          validarCenaBase('c', const CenaHistoria(cenario: CenarioHistoria.cidade, hora: HoraHistoria.dia, falas: []),
              NivelIngles.a1, vazia,
              personagens: personagensHistoria),
          hasLength(1));
      expect(vazia, ['c: cena sem falas']);
    });

    test('validarTextos: false e rotuloPasso: as lições não checam o texto e dizem "passo"', () {
      final erros = <String>[];
      validarCenaBase(
        'l cena[0]',
        const CenaHistoria(
          cenario: CenarioHistoria.casa,
          hora: HoraHistoria.dia,
          elenco: elenco,
          falas: [
            FalaHistoria(quem: 'voce', en: 'a frase com 1 monte de palavras e sem ponto final nenhum', pt: 'x'),
            FalaHistoria(quem: 'mike', en: 'Hi.', pt: 'Oi.', alvo: 'sarah'),
          ],
        ),
        NivelIngles.a1,
        erros,
        personagens: const {'voce', 'mike'},
        validarTextos: false,
        rotuloPasso: 'passo',
      );
      expect(erros, ["l cena[0] passo 2: alvo 'sarah' não é ator presente nem objeto visível"]);
    });

    test('o Turismo continua acusando lucas/julia antes do capítulo 15 (pelo porFala)', () {
      final cap = CapituloHistoria.fromJson({
        'pista': 3,
        'nivel': 'A1',
        'titulo': {'en': 'City Lights', 'pt': 'Luzes'},
        'resumo': 'Um resumo de tamanho suficiente para passar.',
        'palavras': [
          {'en': 'car', 'pt': 'carro'},
          {'en': 'team', 'pt': 'equipe'},
          {'en': 'fast', 'pt': 'rápido'},
        ],
        'intro': [
          {
            'cenario': 'cidade',
            'hora': 'dia',
            'elenco': [
              {'quem': 'voce', 'pos': 'centro'},
              {'quem': 'lucas', 'pos': 'direita'},
            ],
            'falas': [
              {'quem': 'lucas', 'en': 'Good job!', 'pt': 'Bom trabalho!'},
            ],
          },
        ],
        'fim': [
          {
            'cenario': 'cidade',
            'hora': 'dia',
            'elenco': [
              {'quem': 'voce', 'pos': 'centro'},
            ],
            'falas': [
              {'quem': 'voce', 'en': 'Yes!', 'pt': 'Sim!'},
            ],
          },
        ],
        'gancho': {'en': 'What next?', 'pt': 'E agora?'},
      });
      final erros = HistoriaTurismo(const TextoBilingue('The Golden Wheel', 'A Roda de Ouro'), [cap]).validar(totalPistas: 3);
      expect(erros, contains("cap 3 intro[0] fala 1: 'lucas' só fala a partir do capítulo 15"));
    });
  });
}

/// Uma lista de erros que anota a ordem em que eles chegam (junto com as chamadas do porFala).
class _ErrosAnotados extends ListBase<String> {
  _ErrosAnotados(this.ordem);
  final List<String> ordem;
  final _lista = <String>[];

  @override
  int get length => _lista.length;

  @override
  set length(int n) => _lista.length = n;

  @override
  String operator [](int i) => _lista[i];

  @override
  void operator []=(int i, String v) => _lista[i] = v;

  @override
  void add(String element) {
    ordem.add('erro $element');
    _lista.add(element);
  }
}
