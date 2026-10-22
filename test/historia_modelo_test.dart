import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/simulacao_historia.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';

/// O capítulo 1 do plano (seção 11.5), igual a `$SP/historia/exemplo_capitulo.json`.
const exemploCapitulo = r'''
{
  "versao": 2,
  "parte": "a",
  "titulo": {"en": "The Golden Wheel", "pt": "A Roda de Ouro"},
  "capitulos": [
    {
      "pista": 1,
      "nivel": "A1",
      "titulo": {"en": "Hello, Racer!", "pt": "Olá, piloto!"},
      "resumo": "Você chega a Chicago, conhece o time e vira o piloto da equipe de corrida de fim de semana.",
      "palavras": [
        {"en": "car", "pt": "carro"},
        {"en": "team", "pt": "equipe"},
        {"en": "fast", "pt": "rápido"},
        {"en": "gate", "pt": "portão"},
        {"en": "word", "pt": "palavra"}
      ],
      "intro": [
        {
          "cenario": "aeroporto",
          "hora": "dia",
          "clima": [],
          "elenco": [
            {"quem": "voce", "pos": "esquerda", "segura": "mala", "emocao": "feliz"},
            {"quem": "ana", "pos": "centroEsquerda", "segura": "passaporte", "emocao": "feliz"},
            {"quem": "mike", "pos": "centroDireita", "visivel": false, "segura": "radio"},
            {"quem": "sarah", "pos": "direita", "visivel": false, "segura": "livro"}
          ],
          "objetos": [],
          "falas": [
            {"quem": "narrador", "en": "Your first trip to Chicago.", "pt": "Sua primeira viagem a Chicago.", "camera": "panoramica"},
            {"quem": "voce", "en": "I am here! I am really here!", "pt": "Estou aqui! Estou mesmo aqui!", "emocao": "radiante", "acao": "pula", "camera": "geral",
             "reacoes": [{"quem": "ana", "acao": "palmas"}]},
            {"quem": "mike", "en": "Hi! I'm Mike, your tech lead.", "pt": "Oi! Eu sou o Mike, seu tech lead.", "emocao": "feliz", "acao": "entra", "para": "centroDireita"},
            {"quem": "sarah", "en": "I'm Sarah. I have a plan.", "pt": "Eu sou a Sarah. Eu tenho um plano.", "emocao": "determinado", "acao": "entra", "para": "direita",
             "reacoes": [{"quem": "mike", "acao": "concorda"}]},
            {"quem": "sarah", "en": "You type fast. Be our driver!", "pt": "Você digita rápido. Seja o nosso piloto!", "pt_f": "Você digita rápido. Seja a nossa pilota!",
             "emocao": "radiante", "acao": "aponta", "alvo": "voce", "camera": "dupla",
             "reacoes": [{"quem": "voce", "emocao": "surpreso", "efeito": "exclamacao"}]}
          ]
        },
        {
          "cenario": "campina",
          "hora": "amanhecer",
          "clima": [],
          "elenco": [
            {"quem": "voce", "pos": "esquerda", "segura": "capacete", "emocao": "surpreso"},
            {"quem": "ben", "pos": "centroDireita", "emocao": "radiante"},
            {"quem": "mike", "pos": "direita", "segura": "radio", "emocao": "feliz"}
          ],
          "objetos": [{"prop": "carro", "pos": "centro"}],
          "falas": [
            {"quem": "ben", "en": "Hi! I'm Ben. This is your car!", "pt": "Oi! Eu sou o Ben. Este é o seu carro!", "acao": "aponta", "alvo": "carro", "camera": "geral"},
            {"quem": "ben", "mudo": true, "acao": "cai", "efeito": "estalo",
             "reacoes": [{"quem": "voce", "emocao": "nervoso"}, {"quem": "mike", "emocao": "surpreso"}]},
            {"quem": "ben", "en": "I'm okay! I'm okay!", "pt": "Estou bem! Estou bem!", "emocao": "feliz", "acao": "pula",
             "reacoes": [{"quem": "voce", "emocao": "radiante"}, {"quem": "mike", "emocao": "feliz"}]},
            {"quem": "mike", "en": "Type the word. The gate opens.", "pt": "Digite a palavra. O portão abre.", "emocao": "determinado", "acao": "aponta", "camera": "medio"},
            {"quem": "voce", "en": "I know ten racing words. Let's go!", "pt": "Eu sei dez palavras de corrida. Vamos lá!", "emocao": "determinado", "acao": "comemora", "camera": "aproxima"}
          ]
        }
      ],
      "fim": [
        {
          "cenario": "campina",
          "hora": "tarde",
          "clima": [],
          "elenco": [
            {"quem": "ana", "pos": "esquerda", "emocao": "feliz"},
            {"quem": "sarah", "pos": "centroEsquerda", "emocao": "feliz"},
            {"quem": "voce", "pos": "centro", "segura": "capacete", "emocao": "radiante"},
            {"quem": "mike", "pos": "centroDireita", "emocao": "feliz"},
            {"quem": "ben", "pos": "direita", "emocao": "radiante"}
          ],
          "objetos": [],
          "falas": [
            {"quem": "ben", "en": "You did it! Good job!", "pt": "Você conseguiu! Bom trabalho!", "acao": "palmas", "efeito": "confete", "camera": "geral",
             "reacoes": [{"quem": "ana", "acao": "palmas"}, {"quem": "sarah", "acao": "palmas"}, {"quem": "mike", "acao": "comemora"}]},
            {"quem": "voce", "en": "Now I know eleven racing words!", "pt": "Agora eu sei onze palavras de corrida!", "acao": "comemora", "camera": "medio"},
            {"quem": "narrador", "en": "A black car drives by. Fast!", "pt": "Um carro preto passa. Rápido!", "camera": "geral",
             "objetos": [{"prop": "carroRival", "acao": "passa"}],
             "reacoes": [{"quem": "voce", "emocao": "surpreso", "efeito": "interrogacao"}, {"quem": "ben", "emocao": "surpreso"}]}
          ]
        }
      ],
      "gancho": {"en": "But who is the driver in black?", "pt": "Mas quem é o piloto de preto?"}
    }
  ]
}
''';

Map<String, dynamic> _exemplo() => jsonDecode(exemploCapitulo) as Map<String, dynamic>;

Map<String, dynamic> _cap(Map<String, dynamic> j, [int i = 0]) => (j['capitulos'] as List)[i] as Map<String, dynamic>;

Map<String, dynamic> _cena(Map<String, dynamic> j, String parte, int i) =>
    (_cap(j)[parte] as List)[i] as Map<String, dynamic>;

List<dynamic> _falas(Map<String, dynamic> j, String parte, int i) => _cena(j, parte, i)['falas'] as List;

Map<String, dynamic> _fala(Map<String, dynamic> j, String parte, int i, int k) =>
    _falas(j, parte, i)[k] as Map<String, dynamic>;

List<dynamic> _elenco(Map<String, dynamic> j, String parte, int i) => _cena(j, parte, i)['elenco'] as List;

/// Os erros do exemplo depois de [mudar] (parse estrito + validar só do capítulo 1).
List<String> _erros(void Function(Map<String, dynamic> j) mudar) {
  final j = _exemplo();
  mudar(j);
  return HistoriaTurismo.dasPartes([j]).validar(totalPistas: 1);
}

/// [mudar] tem de gerar pelo menos um erro contendo [trecho].
void _falha(String trecho, void Function(Map<String, dynamic> j) mudar) {
  final e = _erros(mudar);
  expect(e.any((m) => m.contains(trecho)), isTrue, reason: 'esperava "$trecho" em $e');
}

/// Uma cena mínima válida para testar a simulação.
CenaHistoria _cenaSim(List<FalaHistoria> falas,
        {List<AtorEmCena>? elenco, List<ObjetoEmCena> objetos = const []}) =>
    CenaHistoria(
      cenario: CenarioHistoria.campina,
      hora: HoraHistoria.dia,
      elenco: elenco ??
          const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro),
            AtorEmCena(quem: 'ben', pos: PosicaoPalco.esquerda),
          ],
      objetos: objetos,
      falas: falas,
    );

void main() {
  group('parse do exemplo (seção 11.5)', () {
    test('estrito: lê o capítulo 1 inteiro', () {
      final h = HistoriaTurismo.dasPartes([_exemplo()]);
      expect(h.titulo.en, 'The Golden Wheel');
      expect(h.capitulos, hasLength(1));
      final c = h.capitulo(1)!;
      expect(c.nivel, NivelIngles.a1);
      expect(c.titulo.en, 'Hello, Racer!');
      expect(c.palavras.map((p) => p.en), ['car', 'team', 'fast', 'gate', 'word']);
      expect(c.intro, hasLength(2));
      expect(c.fim, hasLength(1));
      expect(c.gancho!.en, 'But who is the driver in black?');
      final cena0 = c.intro[0];
      expect(cena0.cenario, CenarioHistoria.aeroporto);
      expect(cena0.elenco[2].visivel, isFalse);
      expect(cena0.elenco[0].segura, PropHistoria.mala);
      expect(cena0.elenco[0].emocao, Expressao.feliz);
      expect(cena0.falas[0].ehNarrador, isTrue);
      expect(cena0.falas[0].camera, CameraHistoria.panoramica);
      expect(cena0.falas[4].ptF, 'Você digita rápido. Seja a nossa pilota!');
      expect(cena0.falas[4].reacoes.single.efeito, EfeitoHistoria.exclamacao);
      final muda = c.intro[1].falas[1];
      expect(muda.mudo, isTrue);
      expect(muda.palavras, 0);
      expect(muda.acao, AcaoAtor.cai);
      expect(c.intro[1].objetos.single.prop, PropHistoria.carro);
      expect(c.fim[0].falas[2].objetos.single.acao, AcaoObjeto.passa);
      expect(c.todasAsFalas.length, 13);
      expect(c.parte(ParteDoCapitulo.fim), same(c.fim));
      expect(cena0.falas[1].palavras, 7);
    });

    test('validar() fica vazio para o exemplo', () {
      expect(HistoriaTurismo.dasPartes([_exemplo()]).validar(totalPistas: 1), isEmpty);
    });

    test('NivelIngles: limites da tabela 5.2', () {
      expect(NivelIngles.values.map((n) => n.maxPalavras), [8, 11, 14, 18]);
      expect(NivelIngles.b1.faixaIntro, (8, 12));
      expect(NivelIngles.a2.faixaFim, (2, 4));
      expect(NivelIngles.b2.json, 'B2');
    });

    test('tabelas de regra', () {
      expect(cenarioDaPista.keys, List.generate(30, (i) => i + 1));
      expect(cenarioDaPista[29], CenarioHistoria.estacao);
      expect(horasPermitidas(CenarioHistoria.lua), {HoraHistoria.noite});
      expect(horasPermitidas(CenarioHistoria.praia), HoraHistoria.values.toSet());
      expect(climaPermitido(ClimaHistoria.chuva, CenarioHistoria.hotel, HoraHistoria.noite), isTrue);
      expect(climaPermitido(ClimaHistoria.neblina, CenarioHistoria.hotel, HoraHistoria.dia), isFalse);
      expect(climaPermitido(ClimaHistoria.neon, CenarioHistoria.estacao, HoraHistoria.noite), isTrue);
      expect(climaPermitido(ClimaHistoria.chuva, CenarioHistoria.estacao, HoraHistoria.noite), isFalse);
      expect(climaPermitido(ClimaHistoria.estrelas, CenarioHistoria.campina, HoraHistoria.dia), isFalse);
      expect(climaPermitido(ClimaHistoria.aurora, CenarioHistoria.neve, HoraHistoria.noite), isTrue);
      expect(climaPermitido(ClimaHistoria.arcoIris, CenarioHistoria.campina, HoraHistoria.tarde), isTrue);
      expect(climaPermitido(ClimaHistoria.arcoIris, CenarioHistoria.marte, HoraHistoria.dia), isFalse);
      expect(climaPermitido(ClimaHistoria.neve, CenarioHistoria.marte, HoraHistoria.dia), isFalse);
      expect(climaPermitido(ClimaHistoria.neon, CenarioHistoria.campina, HoraHistoria.noite), isFalse);
      expect(climaPermitido(ClimaHistoria.neve, CenarioHistoria.lua, HoraHistoria.noite), isFalse);
      expect(personagensHistoria, hasLength(11));
      expect(personagensHistoria.contains(narrador), isFalse);
      expect(acoesDeReacao.contains(AcaoAtor.anda), isFalse);
      expect(paresDeInterferencia, contains(('left', 'right')));
    });
  });

  group('parse estrito × tolerante', () {
    test('estrito: enum inválido vira FormatException com o lugar exato', () {
      final j = _exemplo();
      _fala(j, 'intro', 0, 1)['emocao'] = 'happy';
      expect(
        () => HistoriaTurismo.dasPartes([j]),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', "cap 1 intro[0] fala 2: emocao 'happy' inválida")),
      );
    });

    test('estrito: chave desconhecida, versão errada, capítulo fora da parte e repetido', () {
      final chave = _exemplo();
      _cena(chave, 'fim', 0)['luz'] = 'forte';
      expect(() => HistoriaTurismo.dasPartes([chave]),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains("chave 'luz' desconhecida"))));
      final versao = _exemplo()..['versao'] = 1;
      expect(() => HistoriaTurismo.dasPartes([versao]), throwsFormatException);
      final parte = _exemplo()..['parte'] = 'b';
      expect(() => HistoriaTurismo.dasPartes([parte]),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('fora da faixa'))));
      expect(() => HistoriaTurismo.dasPartes([_exemplo(), _exemplo()]),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('repetido'))));
      final semFalas = _exemplo();
      _cena(semFalas, 'intro', 0).remove('falas');
      expect(() => HistoriaTurismo.dasPartes([semFalas]), throwsFormatException);
    });

    test('tolerante: descarta só o capítulo ruim e cai no default nos enums de enfeite', () {
      final j = _exemplo();
      final ruim = jsonDecode(jsonEncode(_cap(j))) as Map<String, dynamic>;
      ruim['pista'] = 2;
      ((ruim['intro'] as List)[0] as Map<String, dynamic>)['cenario'] = 'lava';
      final bom = jsonDecode(jsonEncode(_cap(j))) as Map<String, dynamic>;
      bom['pista'] = 3;
      ((((bom['intro'] as List)[0] as Map)['falas'] as List)[1] as Map)['emocao'] = 'happy';
      ((((bom['intro'] as List)[0] as Map)['falas'] as List)[1] as Map)['acao'] = 'voa';
      ((((bom['intro'] as List)[0] as Map)['falas'] as List)[1] as Map)['extra'] = true;
      (j['capitulos'] as List).addAll([ruim, bom]);
      final avisos = <String>[];
      final h = HistoriaTurismo.dasPartes([j], estrito: false, aviso: avisos.add);
      expect(h.capitulos.map((c) => c.pista), [1, 3]);
      expect(avisos.where((a) => a.contains('cap 2')), hasLength(1));
      final f = h.capitulo(3)!.intro[0].falas[1];
      expect(f.emocao, Expressao.neutro);
      expect(f.acao, AcaoAtor.parado);
      // o mesmo conteúdo no estrito derruba tudo
      expect(() => HistoriaTurismo.dasPartes([j]), throwsFormatException);
    });

    test('ordena os capítulos por pista ao juntar as partes', () {
      final a = _exemplo();
      final c2 = jsonDecode(jsonEncode(_cap(a))) as Map<String, dynamic>..['pista'] = 2;
      (a['capitulos'] as List).insert(0, c2);
      final h = HistoriaTurismo.dasPartes([a], estrito: false);
      expect(h.capitulos.map((c) => c.pista), [1, 2]);
    });
  });

  group('validar() — um caso negativo por regra (seção 11.4)', () {
    test('V-arquivo: cobertura 1..totalPistas', () {
      final h = HistoriaTurismo.dasPartes([_exemplo()]);
      expect(h.validar(totalPistas: 2), contains('cap 2: ausente'));
      expect(h.validar(), hasLength(29));
    });

    test('V-capítulo', () {
      _falha('nivel A2', (j) => _cap(j)['nivel'] = 'A2');
      _falha('titulo', (j) => (_cap(j)['titulo'] as Map)['en'] = 'Hello!');
      _falha('resumo', (j) => _cap(j)['resumo'] = 'Curto.');
      _falha('palavras (3–6)', (j) => (_cap(j)['palavras'] as List).removeRange(2, 5));
      _falha('par de interferência left/right', (j) {
        (_cap(j)['palavras'] as List).removeRange(3, 5);
        (_cap(j)['palavras'] as List).addAll([
          {'en': 'left', 'pt': 'esquerda'},
          {'en': 'right', 'pt': 'direita'},
        ]);
      });
      _falha('minúsculas', (j) => ((_cap(j)['palavras'] as List)[0] as Map)['en'] = 'Car');
      _falha('gancho obrigatório', (j) => _cap(j).remove('gancho'));
      _falha('cenas', (j) => (_cap(j)['fim'] as List).addAll([_cena(j, 'fim', 0), _cena(j, 'fim', 0)]));
    });

    test('V-contagem', () {
      _falha('palavras no en (máx. 8)', (j) => _fala(j, 'intro', 0, 1)['en'] = 'I am here and I am really really here!');
      _falha('fim com 1 falas com texto (2–4)', (j) => _falas(j, 'fim', 0).removeRange(0, 2));
      _falha('intro com 5 falas com texto (6–9)', (j) => _falas(j, 'intro', 0).removeRange(1, 5));
    });

    test('V-texto', () {
      _falha('terminar com', (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip to Chicago');
      _falha('pontuação proibida', (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip...');
      _falha('pontuação proibida', (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip — wow!');
      _falha('ASCII', (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip to Chicagó.');
      _falha('ASCII', (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip! 🚗');
      _falha('gonna', (j) => _fala(j, 'intro', 0, 0)['en'] = "We're gonna win.");
      _falha("termo proibido 'paris'", (j) => _fala(j, 'intro', 0, 0)['pt'] = 'Sua primeira viagem a Paris.');
      _falha("termo proibido 'ferrari'", (j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first Ferrari.');
      _falha('pt vazio', (j) => _fala(j, 'intro', 0, 0)['pt'] = ' ');
      _falha('gancho', (j) => (_cap(j)['gancho'] as Map)['en'] = 'But who is the driver in black');
      // reticências de um caractere são permitidas
      expect(_erros((j) => _fala(j, 'intro', 0, 0)['en'] = 'Your first trip… to Chicago.'), isEmpty);
    });

    test('V-elenco', () {
      _falha("personagem 'zeca' desconhecido", (j) => (_elenco(j, 'fim', 0)[0] as Map)['quem'] = 'zeca');
      _falha('o narrador não entra no elenco', (j) => (_elenco(j, 'fim', 0)[0] as Map)['quem'] = 'narrador');
      _falha("'ana' repetido", (j) => (_elenco(j, 'fim', 0)[1] as Map)['quem'] = 'ana');
      _falha("posição inicial 'esquerda' repetida", (j) => (_elenco(j, 'fim', 0)[1] as Map)['pos'] = 'esquerda');
      _falha('6 atores presentes', (j) {
        _elenco(j, 'intro', 1).addAll([
          {'quem': 'ana', 'pos': 'centroEsquerda'},
          {'quem': 'sarah', 'pos': 'centro', 'visivel': false},
          {'quem': 'emma', 'pos': 'centroEsquerda', 'visivel': false},
        ]);
      });
      _falha('remoto e não tem pos', (j) => (_elenco(j, 'intro', 1)[2] as Map)['remoto'] = 'radio');
      _falha("'voce' sem pos", (j) => (_elenco(j, 'intro', 1)[0] as Map).remove('pos'));
      _falha("'lucas' só fala a partir do capítulo 15", (j) {
        _elenco(j, 'fim', 0).add({'quem': 'lucas', 'remoto': 'celular'});
        (_elenco(j, 'fim', 0)[2] as Map)['segura'] = 'celular';
        _falas(j, 'fim', 0).insert(0, {'quem': 'lucas', 'en': 'Good job!', 'pt': 'Bom trabalho!'});
      });
    });

    test('V-hora/clima', () {
      _falha("hora 'dia' não combina com 'espaco'", (j) {
        _cena(j, 'fim', 0)['cenario'] = 'espaco';
        _cena(j, 'fim', 0)['hora'] = 'dia';
      });
      _falha("clima 'estrelas'", (j) => _cena(j, 'intro', 1)['clima'] = ['estrelas']);
      _falha("clima 'neblina'", (j) => _cena(j, 'intro', 0)['clima'] = ['neblina']);
      _falha("clima 'neon'", (j) => _cena(j, 'fim', 0)['clima'] = ['neon']);
      _falha('clima repetido', (j) => _cena(j, 'fim', 0)['clima'] = ['vento', 'vento']);
      // troca de hora no meio da cena valida o clima herdado
      _falha("clima 'arcoIris'", (j) {
        _cena(j, 'fim', 0)['clima'] = ['arcoIris'];
        _fala(j, 'fim', 0, 2)['hora'] = 'noite';
      });
      expect(_erros((j) => _cena(j, 'intro', 0)['clima'] = ['chuva']), isEmpty);
    });

    test('V-passo (simulado)', () {
      _falha("'mike' não está visível", (j) => _fala(j, 'intro', 0, 2).remove('acao'));
      _falha("'ana' já está visível (entra)", (j) {
        _fala(j, 'intro', 0, 0)['quem'] = 'ana';
        _fala(j, 'intro', 0, 0)['acao'] = 'entra';
      });
      _falha("acao 'abraca' exige alvo", (j) => _fala(j, 'fim', 0, 1)['acao'] = 'abraca');
      _falha("alvo 'kim'", (j) => _fala(j, 'intro', 1, 0)['alvo'] = 'kim');
      _falha("alvo 'trofeu'", (j) => _fala(j, 'intro', 1, 0)['alvo'] = 'trofeu');
      _falha("alvo 'sarah'", (j) => _fala(j, 'intro', 0, 1)['alvo'] = 'sarah'); // ainda invisível
      _falha("acao 'anda' exige para", (j) => _fala(j, 'fim', 0, 1)['acao'] = 'anda');
      _falha("'para' só em anda", (j) => _fala(j, 'fim', 0, 1)['para'] = 'esquerda');
      _falha('camera dupla exige alvo ator', (j) => _fala(j, 'fim', 0, 1)['camera'] = 'dupla');
      _falha('passo mudo não leva en/pt', (j) => _fala(j, 'intro', 1, 1)['en'] = 'Oops!');
      _falha('passo mudo sem nada acontecendo', (j) => _falas(j, 'intro', 1)[1] = {'quem': 'ben', 'mudo': true});
      _falha('passo mudo exige um ator presente', (j) => _fala(j, 'intro', 1, 1)['quem'] = 'narrador');
      _falha('mais de 2 passos mudos seguidos', (j) {
        final muda = _fala(j, 'intro', 1, 1);
        _falas(j, 'intro', 1).insertAll(1, [
          {'quem': 'ben', 'mudo': true, 'acao': 'pula'},
          {'quem': 'ben', 'mudo': true, 'acao': 'acena'},
        ]);
        expect(muda['mudo'], isTrue);
      });
      _falha('o narrador não faz ação', (j) => _fala(j, 'intro', 0, 0)['acao'] = 'pula');
      _falha('o narrador não segura nada', (j) => _fala(j, 'intro', 0, 0)['segura'] = 'mapa');
      _falha("'mike' fala pelo rádio", (j) {
        (_elenco(j, 'intro', 1)[2] as Map)
          ..remove('pos')
          ..remove('segura')
          ..['remoto'] = 'radio';
        _fala(j, 'intro', 1, 3).remove('acao');
        _fala(j, 'intro', 1, 3).remove('camera');
        (_fala(j, 'intro', 1, 1)['reacoes'] as List).removeAt(1);
        (_fala(j, 'intro', 1, 2)['reacoes'] as List).removeAt(1);
      });
      _falha("'mike' é remoto: só acao parado", (j) {
        (_elenco(j, 'intro', 1)[2] as Map)
          ..remove('pos')
          ..['remoto'] = 'radio';
        (_elenco(j, 'intro', 1)[0] as Map)['segura'] = 'radio';
        (_fala(j, 'intro', 1, 1)['reacoes'] as List).removeAt(1);
        (_fala(j, 'intro', 1, 2)['reacoes'] as List).removeAt(1);
      });
      _falha("'ben' não está no carro (desce)", (j) => _fala(j, 'intro', 1, 0)['acao'] = 'desce');
      _falha("'ben' mostra sem nada na mão", (j) => _fala(j, 'intro', 1, 0)['acao'] = 'mostra');
      _falha('escreve sem prop', (j) => _fala(j, 'fim', 0, 0)['acao'] = 'escreve');
      _falha("dois atores em 'centroEsquerda'", (j) => _fala(j, 'intro', 0, 3)['para'] = 'centroEsquerda');
      _falha("reação de 'sarah', que não está visível", (j) => (_fala(j, 'intro', 0, 1)['reacoes'] as List)[0] = {'quem': 'sarah', 'emocao': 'feliz'});
      _falha("não reage à própria fala", (j) => (_fala(j, 'intro', 0, 1)['reacoes'] as List)[0] = {'quem': 'voce', 'emocao': 'feliz'});
      _falha("acao 'corre' não vale numa reação", (j) => (_fala(j, 'intro', 0, 1)['reacoes'] as List)[0] = {'quem': 'ana', 'acao': 'corre'});
      _falha('precisa de exatamente 1 objeto visível', (j) => _fala(j, 'fim', 0, 2)['objetos'] = [{'prop': 'trofeu', 'acao': 'some'}]);
      _falha("'ben' não segura 'mapa'", (j) => _fala(j, 'fim', 0, 0)['objetos'] = [{'prop': 'mapa', 'acao': 'voa', 'de': 'ben'}]);
      _falha('exige pos', (j) => _fala(j, 'fim', 0, 2)['objetos'] = [{'prop': 'trofeu', 'acao': 'aparece'}]);
      _falha('não leva pos', (j) => _fala(j, 'fim', 0, 2)['objetos'] = [{'prop': 'carroRival', 'acao': 'passa', 'pos': 'centro'}]);
      _falha("dois objetos em 'centro'", (j) => _fala(j, 'intro', 1, 3)['objetos'] = [{'prop': 'trofeu', 'acao': 'aparece', 'pos': 'centro'}]);
      _falha("não está no elenco da cena", (j) => _fala(j, 'fim', 0, 1)['quem'] = 'kim');
    });

    test('V-mundo', () {
      _falha('V-mundo', (j) => _cena(j, 'intro', 1)['cenario'] = 'deserto');
      // vale a troca de cenário dentro da cena (a última fala acontece na campina)
      expect(
        _erros((j) {
          _cena(j, 'intro', 1)['cenario'] = 'boxes';
          _fala(j, 'intro', 1, 4)['cenario'] = 'campina';
        }),
        isEmpty,
      );
    });

    test('V-fim', () {
      _falha('a fim termina num passo mudo', (j) => _falas(j, 'fim', 0).add({'quem': 'ben', 'mudo': true, 'acao': 'pula'}));
      _falha('a intro termina num passo mudo', (j) => _falas(j, 'intro', 1).add({'quem': 'ben', 'mudo': true, 'acao': 'pula'}));
    });
  });

  group('SimulacaoCena', () {
    test('linha do tempo do exemplo: posições, visibilidade, prop na mão e emoção', () {
      final c = HistoriaTurismo.dasPartes([_exemplo()]).capitulo(1)!;
      final aero = SimulacaoCena.linhaDoTempo(c.intro[0]);
      expect(aero, hasLength(c.intro[0].falas.length + 1));
      expect(aero.first.atores['mike']!.visivel, isFalse);
      expect(aero.first.camera, CameraHistoria.geral);
      expect(aero[1].camera, CameraHistoria.panoramica);
      expect(aero[3].atores['mike']!.visivel, isTrue);
      expect(aero[3].atores['sarah']!.visivel, isFalse);
      final fimAero = aero.last;
      expect(fimAero.atores['mike']!.pos, PosicaoPalco.centroDireita);
      expect(fimAero.atores['sarah']!.pos, PosicaoPalco.direita);
      expect(fimAero.atores['sarah']!.visivel, isTrue);
      expect(fimAero.atores['sarah']!.emocao, Expressao.radiante);
      expect(fimAero.atores['voce']!.segura, PropHistoria.mala);
      expect(fimAero.atores['voce']!.emocao, Expressao.surpreso);
      expect(fimAero.atores['ana']!.segura, PropHistoria.passaporte);
      expect(fimAero.camera, CameraHistoria.dupla);
      // Sarah à direita aponta para o aluno à esquerda: olha para a esquerda
      expect(fimAero.atores['sarah']!.olhaParaEsquerda, isTrue);
      expect(fimAero.atores['voce']!.olhaParaEsquerda, isFalse);

      final campina = SimulacaoCena.linhaDoTempo(c.intro[1]);
      expect(campina.last.atores['ben']!.pos, PosicaoPalco.centroDireita);
      expect(campina.last.atores['ben']!.emocao, Expressao.feliz);
      expect(campina.last.atores['voce']!.emocao, Expressao.determinado);
      expect(campina.last.atores['voce']!.segura, PropHistoria.capacete);
      expect(campina.last.objetos.single.visivel, isTrue);
      expect(campina.last.camera, CameraHistoria.aproxima);

      final fim = SimulacaoCena.linhaDoTempo(c.fim[0]);
      expect(fim.last.objetos.where((o) => o.visivel), isEmpty); // o carro preto só passa
      expect(fim.last.atores['voce']!.emocao, Expressao.surpreso);
      // o estado anterior não muda (cópia profunda)
      expect(fim.first.atores['voce']!.emocao, Expressao.radiante);
    });

    test('dirige/desce: o carro da mesma posição some enquanto ele dirige e volta onde ele desce', () {
      final cena = _cenaSim(
        const [
          FalaHistoria(quem: 'voce', en: 'Let me drive.', pt: 'Deixa eu dirigir.', acao: AcaoAtor.dirige),
          FalaHistoria(quem: 'voce', en: 'Here I go!', pt: 'Lá vou eu!', acao: AcaoAtor.anda, para: PosicaoPalco.direita),
          FalaHistoria(quem: 'voce', en: 'I stop here.', pt: 'Paro aqui.', acao: AcaoAtor.desce),
        ],
        objetos: const [ObjetoEmCena(prop: PropHistoria.carro, pos: PosicaoPalco.centro)],
      );
      final l = SimulacaoCena.linhaDoTempo(cena);
      expect(l[1].atores['voce']!.noCarro, isTrue);
      expect(l[1].objetos.single.visivel, isFalse);
      expect(l[1].objetos.single.absorvidoPor, 'voce');
      expect(l[2].atores['voce']!.pos, PosicaoPalco.direita);
      expect(l[3].atores['voce']!.noCarro, isFalse);
      expect(l[3].objetos.single.visivel, isTrue);
      expect(l[3].objetos.single.pos, PosicaoPalco.direita);
      expect(l[3].objetos.single.absorvidoPor, isNull);
    });

    test('desce sem carro absorvido cria o carro do ator; senta, dorme e levanta', () {
      final cena = _cenaSim(
        const [
          FalaHistoria(quem: 'max', en: 'Out of my car.', pt: 'Saio do carro.', acao: AcaoAtor.desce),
          FalaHistoria(quem: 'max', mudo: true, acao: AcaoAtor.senta),
          FalaHistoria(quem: 'max', mudo: true, acao: AcaoAtor.dorme, efeito: EfeitoHistoria.zzz),
          FalaHistoria(quem: 'voce', en: 'Wake up!', pt: 'Acorda!', reacoes: [
            ReacaoHistoria(quem: 'max', acao: AcaoAtor.pula, emocao: Expressao.surpreso),
          ]),
        ],
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.esquerda),
          AtorEmCena(quem: 'max', pos: PosicaoPalco.direita, noCarro: true),
        ],
      );
      final l = SimulacaoCena.linhaDoTempo(cena);
      expect(l[1].objetos.single.prop, PropHistoria.carroRival);
      expect(l[1].objetos.single.pos, PosicaoPalco.direita);
      expect(l[2].atores['max']!.sentado, isTrue);
      expect(l[3].atores['max']!.dormindo, isTrue);
      expect(l[3].atores['max']!.sentado, isTrue);
      expect(l[4].atores['max']!.dormindo, isFalse);
      expect(l[4].atores['max']!.sentado, isFalse);
      expect(l[4].atores['max']!.emocao, Expressao.surpreso);
    });

    test('objetos: aparece revela o guardado, voa da mão, entra e sai', () {
      final cena = _cenaSim(
        const [
          FalaHistoria(quem: 'voce', en: 'Look!', pt: 'Olha!', objetos: [
            MovimentoObjeto(prop: PropHistoria.trofeu, acao: AcaoObjeto.aparece, pos: PosicaoPalco.centroDireita),
          ]),
          FalaHistoria(quem: 'ben', en: 'My map!', pt: 'Meu mapa!', objetos: [
            MovimentoObjeto(prop: PropHistoria.mapa, acao: AcaoObjeto.voa, de: 'ben'),
          ]),
          FalaHistoria(quem: 'voce', en: 'Bye, cup!', pt: 'Tchau, taça!', objetos: [
            MovimentoObjeto(prop: PropHistoria.trofeu, acao: AcaoObjeto.sai),
          ]),
        ],
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro),
          AtorEmCena(quem: 'ben', pos: PosicaoPalco.esquerda, segura: PropHistoria.mapa),
        ],
        objetos: const [ObjetoEmCena(prop: PropHistoria.trofeu, pos: PosicaoPalco.direita, visivel: false)],
      );
      final l = SimulacaoCena.linhaDoTempo(cena);
      expect(l[1].objetos, hasLength(1));
      expect(l[1].objetos.single.visivel, isTrue);
      expect(l[1].objetos.single.pos, PosicaoPalco.centroDireita);
      expect(l[2].atores['ben']!.segura, isNull);
      expect(l[3].objetos.single.visivel, isFalse);
      for (var i = 0; i < cena.falas.length; i++) {
        expect(SimulacaoCena.aplicar(l[i], cena.falas[i]).$2, isEmpty);
      }
    });

    test('aplicar devolve os erros do passo sem prefixo e não altera o estado anterior', () {
      final cena = _cenaSim(const [FalaHistoria(quem: 'ben', en: 'Hi!', pt: 'Oi!', acao: AcaoAtor.anda)]);
      final antes = EstadoCena.inicial(cena);
      final (depois, erros) = SimulacaoCena.aplicar(antes, cena.falas.single);
      expect(erros, ["acao 'anda' exige para"]);
      expect(identical(antes, depois), isFalse);
      expect(antes.atores['ben']!.pos, PosicaoPalco.esquerda);
    });

    test('remoto: não ocupa posição e fala pelo rádio de quem está no carro', () {
      final cena = _cenaSim(
        const [
          FalaHistoria(quem: 'voce', en: "I can't see the road!", pt: 'Não consigo ver a estrada!'),
          FalaHistoria(quem: 'mike', en: 'You can hear me.', pt: 'Você consegue me ouvir.', emocao: Expressao.feliz),
        ],
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro, noCarro: true, emocao: Expressao.nervoso),
          AtorEmCena(quem: 'mike', remoto: ViaRemota.radio, emocao: Expressao.determinado),
        ],
      );
      final l = SimulacaoCena.linhaDoTempo(cena);
      expect(l.first.atores['mike']!.ehRemoto, isTrue);
      expect(l.first.atores['mike']!.pos, isNull);
      expect(l.first.atores['mike']!.visivel, isFalse);
      expect(l.last.atores['mike']!.emocao, Expressao.feliz);
      expect(SimulacaoCena.aplicar(l[1], cena.falas[1]).$2, isEmpty);
    });

    test('duracaoDe: tabela 5.3', () {
      expect(SimulacaoCena.duracaoDe(AcaoAtor.acena), 1.2);
      expect(SimulacaoCena.duracaoDe(AcaoAtor.corre), .5);
      expect(SimulacaoCena.duracaoDe(AcaoAtor.olha), .3);
      expect(SimulacaoCena.duracaoDe(AcaoAtor.aponta), isNull);
      expect(SimulacaoCena.duracaoDe(AcaoAtor.dorme), isNull);
      expect(SimulacaoCena.duracaoDe(AcaoAtor.parado), isNull);
    });
  });
}
