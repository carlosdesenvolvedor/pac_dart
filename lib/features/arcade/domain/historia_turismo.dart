import '../../ingles/domain/expressao.dart';
import 'simulacao_historia.dart';

/// 📖 A história do English Turismo, "The Golden Wheel / A Roda de Ouro": um capítulo por pista (1–30),
/// com uma ABERTURA antes da corrida e uma CHEGADA depois. Este arquivo é o modelo (Dart puro): enums com
/// os mesmos nomes do JSON, as tabelas de regra, o parse estrito/tolerante e o [HistoriaTurismo.validar].
///
/// O validador offline (`validar_historia.py`, no scratchpad) lê os enums e as consts DAQUI por regex —
/// em divergência, este arquivo manda. Mantenha cada enum/const no formato `enum X { a, b }` e
/// `const ... nome = {...};`.

/// O nível do inglês de um capítulo. No JSON: "A1".."B2".
enum NivelIngles {
  a1,
  a2,
  b1,
  b2;

  /// Máximo de palavras (tokens separados por espaço) num `en`.
  int get maxPalavras => const [8, 11, 14, 18][index];

  /// Falas com texto na abertura (soma das cenas), mínimo e máximo.
  (int, int) get faixaIntro => const [(6, 9), (7, 10), (8, 12), (8, 12)][index];

  /// Falas com texto na chegada (o capítulo 30 usa [faixaFimFinal]).
  (int, int) get faixaFim => const [(2, 4), (2, 4), (2, 5), (2, 5)][index];

  /// O nome no JSON ("A1").
  String get json => name.toUpperCase();
}

enum ParteDoCapitulo { intro, fim }

enum PosicaoPalco { esquerda, centroEsquerda, centro, centroDireita, direita }

enum ViaRemota { radio, celular }

enum AcaoAtor { parado, acena, pula, comemora, aponta, entra, sai, anda, corre, danca, treme, cai, abraca, pensa,
  palmas, concorda, nega, mostra, dirige, desce, olha, arremessa, escreve, rodopia, senta, dorme }

enum CenarioHistoria { aeroporto, garagem, boxes, hotel, cafe, clinica, plataforma, podio, campina, deserto, cidade,
  neve, vulcao, espaco, praia, ponte, canion, oasis, floresta, vale, lago, lua, marte, estacao, autodromo,
  videochamada, escritorio, casa, restaurante, loja }

enum HoraHistoria { amanhecer, dia, tarde, noite }

enum ClimaHistoria { chuva, neve, neblina, areia, folhas, estrelas, brasas, aurora, vento, neon, arcoIris }

enum EfeitoHistoria { confete, fogos, relampago, coracoes, brilho, fumaca, notas, interrogacao, exclamacao, suor, zzz,
  estalo, estrelaCadente }

enum PropHistoria { nada, carro, carroRival, trofeu, rodaDeOuro, mapa, celular, bandeira, capacete, chave, mala,
  passaporte, cafe, medalha, guardaChuva, microfone, foguete, presente, livro, pneu, cachecol, garrafa, carta, radio,
  notebook, prato, sacola, documento }

enum AcaoObjeto { aparece, some, entra, sai, passa, voa, roda, treme }

enum CameraHistoria { geral, medio, close, dupla, panoramica, aproxima, tremida }

/// Os personagens com corpo (o `narrador` não tem: vira faixa de legenda).
const personagensHistoria = {'voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee', 'max', 'kim'};
const narrador = 'narrador';

const interioresHistoria = {CenarioHistoria.aeroporto, CenarioHistoria.garagem, CenarioHistoria.hotel,
  CenarioHistoria.cafe, CenarioHistoria.clinica, CenarioHistoria.estacao, CenarioHistoria.videochamada,
  CenarioHistoria.escritorio, CenarioHistoria.casa, CenarioHistoria.restaurante, CenarioHistoria.loja};
const espaciaisHistoria = {CenarioHistoria.espaco, CenarioHistoria.lua, CenarioHistoria.estacao};

/// O mundo de cada pista (regra V-mundo: a 1ª ou a última fala da abertura acontece nele).
const Map<int, CenarioHistoria> cenarioDaPista = {
  1: CenarioHistoria.campina,
  2: CenarioHistoria.deserto,
  3: CenarioHistoria.cidade,
  4: CenarioHistoria.neve,
  5: CenarioHistoria.vulcao,
  6: CenarioHistoria.espaco,
  7: CenarioHistoria.campina,
  8: CenarioHistoria.deserto,
  9: CenarioHistoria.cidade,
  10: CenarioHistoria.espaco,
  11: CenarioHistoria.campina,
  12: CenarioHistoria.vale,
  13: CenarioHistoria.floresta,
  14: CenarioHistoria.campina,
  15: CenarioHistoria.praia,
  16: CenarioHistoria.ponte,
  17: CenarioHistoria.canion,
  18: CenarioHistoria.deserto,
  19: CenarioHistoria.oasis,
  20: CenarioHistoria.cidade,
  21: CenarioHistoria.cidade,
  22: CenarioHistoria.cidade,
  23: CenarioHistoria.neve,
  24: CenarioHistoria.lago,
  25: CenarioHistoria.neve,
  26: CenarioHistoria.vulcao,
  27: CenarioHistoria.lua,
  28: CenarioHistoria.marte,
  29: CenarioHistoria.estacao,
  30: CenarioHistoria.autodromo,
};

/// O título em inglês de cada capítulo (tabela 5.4 do plano), na ordem das pistas 1..30.
const List<String> _titulosEn = [
  'Hello, Racer!',
  'The Driver in Black',
  'City Lights',
  'Cold Hands, Warm Heart',
  'Breathe',
  'To the Stars',
  'Left or Right?',
  'The Long Night',
  'Twenty-Four Hours',
  'The Silver Cup',
  'An Old Map',
  'Trust the Voice',
  'A Friend in Trouble',
  'Rain or Shine',
  'Surprise at the Beach',
  "Don't Look Down",
  'Echoes',
  'Sand and Words',
  'The Legend',
  'The Map Comes Back',
  'Slippery Streets',
  'Neon Heart',
  'Whiteout',
  'On Thin Ice',
  'Under the Aurora',
  'Fire Mountain',
  'Radio Silence',
  'Red Dust',
  'The Night Before',
  'The Golden Wheel',
];

/// Ações que uma REAÇÃO pode usar (sem deslocamento: quem reage fica onde está).
const Set<AcaoAtor> acoesDeReacao = {AcaoAtor.parado, AcaoAtor.acena, AcaoAtor.pula, AcaoAtor.comemora,
  AcaoAtor.aponta, AcaoAtor.danca, AcaoAtor.treme, AcaoAtor.cai, AcaoAtor.pensa, AcaoAtor.palmas, AcaoAtor.concorda,
  AcaoAtor.nega, AcaoAtor.mostra, AcaoAtor.olha, AcaoAtor.rodopia, AcaoAtor.senta, AcaoAtor.dorme, AcaoAtor.escreve};

/// Pares de interferência (DESIGN.md §5.5), em minúsculas: nunca os dois nas `palavras` do mesmo capítulo.
const List<(String, String)> paresDeInterferencia = [
  ('left', 'right'),
  ('good evening', 'good night'),
  ('thirteen', 'thirty'),
  ('lend', 'borrow'),
  ('make', 'do'),
  ('say', 'tell'),
  ('come', 'go'),
  ('bring', 'take'),
  ('meet', 'know'),
  ('miss', 'lose'),
  ('miss', 'waste'),
  ('lose', 'waste'),
  ('win', 'earn'),
  ('hear', 'see'),
  ('a few', 'a little'),
  ('put on', 'take off'),
  ('despite', 'in spite of'),
  ('get along with', 'get on with'),
  ('should have', 'was supposed to'),
  ('look at', 'look for'),
  ('look at', 'look after'),
  ('look for', 'look after'),
  ('i think so', "i don't think so"),
  ('far', 'near'),
  ('this', 'that'),
];

/// Termos proibidos em `en`/`pt` (palavra inteira, sem diferenciar maiúsculas): marcas de carro, tecnologia,
/// redes, comida e bebida, e cidades reais além de Chicago (DESIGN.md §5.7 + bíblia §6).
const List<String> termosProibidos = [
  // carros e corrida
  'ferrari', 'porsche', 'lamborghini', 'toyota', 'honda', 'ford', 'chevrolet', 'bmw', 'mercedes', 'audi',
  'volkswagen', 'fiat', 'tesla', 'nissan', 'hyundai', 'renault', 'peugeot', 'mclaren', 'red bull', 'formula 1',
  // tecnologia e redes
  'google', 'iphone', 'android', 'samsung', 'microsoft', 'netflix', 'spotify', 'uber', 'facebook', 'instagram',
  'tiktok', 'whatsapp', 'youtube', 'twitter', 'snapchat', 'slack', 'zoom',
  // comida, bebida e lojas
  'coca-cola', 'coca', 'pepsi', 'fanta', 'mcdonald', "mcdonald's", 'burger king', 'starbucks', 'nescafe',
  'nutella', 'kfc', 'lego', 'nike', 'adidas',
  // cidades reais (só Chicago pode)
  'austin', 'boston', 'recife', 'new york', 'los angeles', 'san francisco', 'miami', 'las vegas', 'houston',
  'dallas', 'seattle', 'detroit', 'orlando', 'washington', 'london', 'paris', 'rome', 'tokyo', 'berlin', 'madrid',
  'lisbon', 'dubai', 'sydney', 'toronto', 'moscow', 'beijing', 'seoul', 'mexico city', 'buenos aires',
  'rio de janeiro', 'sao paulo', 'são paulo', 'brasilia', 'brasília', 'curitiba', 'fortaleza', 'belo horizonte',
  'porto alegre', 'manaus', 'monaco', 'interlagos', 'silverstone', 'daytona', 'le mans',
];

/// Palavras com maiúscula aceitas nas `palavras` do capítulo (o resto vai em minúsculas).
const _nomesProprios = {'I', 'Mike', 'Sarah', 'Ana', 'Ben', 'Emma', 'Lucas', 'Julia', 'Lee', 'Dra.', 'Max', 'Kim',
  'Chicago', 'Team', 'Star', 'Thunder', 'Earth', 'Moon', 'Mars'};

/// As horas em que o cenário [c] pode acontecer (os espaciais só de `noite`).
Set<HoraHistoria> horasPermitidas(CenarioHistoria c) => espaciaisHistoria.contains(c)
    ? const {HoraHistoria.noite}
    : const {HoraHistoria.amanhecer, HoraHistoria.dia, HoraHistoria.tarde, HoraHistoria.noite};

/// O clima [cl] combina com o cenário [c] na hora [h]? (regras V-clima, seção 11.4 do plano)
bool climaPermitido(ClimaHistoria cl, CenarioHistoria c, HoraHistoria h) {
  if ((cl == ClimaHistoria.estrelas || cl == ClimaHistoria.aurora) && h != HoraHistoria.noite) return false;
  if (c == CenarioHistoria.estacao) return cl == ClimaHistoria.estrelas || cl == ClimaHistoria.neon;
  if (interioresHistoria.contains(c)) return cl == ClimaHistoria.chuva || cl == ClimaHistoria.neve;
  if (c == CenarioHistoria.espaco || c == CenarioHistoria.lua) return cl == ClimaHistoria.estrelas;
  if (c == CenarioHistoria.marte &&
      cl != ClimaHistoria.areia &&
      cl != ClimaHistoria.vento &&
      cl != ClimaHistoria.estrelas) {
    return false;
  }
  if (cl == ClimaHistoria.arcoIris) {
    return (h == HoraHistoria.dia || h == HoraHistoria.tarde) && c != CenarioHistoria.marte;
  }
  if (cl == ClimaHistoria.neon) {
    return c == CenarioHistoria.cidade ||
        c == CenarioHistoria.estacao ||
        c == CenarioHistoria.autodromo ||
        c == CenarioHistoria.podio;
  }
  return true;
}

const Expressao emocaoPadrao = Expressao.neutro;

/// Falas com texto na chegada do capítulo 30 (o final, em até 4 cenas).
const (int, int) faixaFimFinal = (10, 16);

// ───────────────────────────── parse ─────────────────────────────

Never _erro(String ctx, String msg) => throw FormatException(ctx.isEmpty ? msg : '$ctx: $msg');

void _chaves(Map<String, dynamic> j, Set<String> validas, String ctx, bool estrito) {
  if (!estrito) return;
  for (final k in j.keys) {
    if (!validas.contains(k)) _erro(ctx, "chave '$k' desconhecida");
  }
}

Map<String, dynamic> _mapa(Object? v, String ctx) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, x) => MapEntry('$k', x));
  _erro(ctx, 'esperava um objeto JSON');
}

String _texto(Map<String, dynamic> j, String campo, String ctx) {
  final v = j[campo];
  if (v is! String) _erro(ctx, "'$campo' ausente ou não é texto");
  return v;
}

String? _textoOpc(Map<String, dynamic> j, String campo, String ctx, bool estrito) {
  final v = j[campo];
  if (v == null) return null;
  if (v is String) return v;
  if (estrito) _erro(ctx, "'$campo' não é texto");
  return null;
}

bool _bool(Map<String, dynamic> j, String campo, bool padrao, String ctx, bool estrito) {
  final v = j[campo];
  if (v == null) return padrao;
  if (v is bool) return v;
  if (estrito) _erro(ctx, "'$campo' não é true/false");
  return padrao;
}

/// Campos femininos, para a mensagem de erro ("emocao 'happy' inválida").
const _camposFemininos = {'emocao', 'acao', 'hora', 'camera', 'pos', 'para'};

String _invalido(String campo, Object? v) => "$campo '$v' ${_camposFemininos.contains(campo) ? 'inválida' : 'inválido'}";

T? _achar<T extends Enum>(List<T> valores, Object? v) {
  if (v is! String) return null;
  for (final e in valores) {
    if (e.name == v) return e;
  }
  return null;
}

/// Enum obrigatório: inválido → erro (no tolerante, cai em [padrao] quando há um).
T _enum<T extends Enum>(List<T> valores, Map<String, dynamic> j, String campo, String ctx, bool estrito,
    {T? padrao}) {
  final v = j[campo];
  final e = _achar(valores, v);
  if (e != null) return e;
  if (v == null && padrao != null) return padrao;
  if (estrito || padrao == null) _erro(ctx, v == null ? "'$campo' ausente" : _invalido(campo, v));
  return padrao;
}

/// Enum opcional: ausente → null; inválido → erro no estrito, [padraoTolerante] no tolerante.
T? _enumOpc<T extends Enum>(List<T> valores, Map<String, dynamic> j, String campo, String ctx, bool estrito,
    {T? padraoTolerante}) {
  final v = j[campo];
  if (v == null) return null;
  final e = _achar(valores, v);
  if (e != null) return e;
  if (estrito) _erro(ctx, _invalido(campo, v));
  return padraoTolerante;
}

/// Enum de posição/estrutura: inválido é erro nos dois modos (sem ele a cena não faz sentido).
T? _enumEstrutural<T extends Enum>(List<T> valores, Map<String, dynamic> j, String campo, String ctx) {
  final v = j[campo];
  if (v == null) return null;
  return _achar(valores, v) ?? _erro(ctx, _invalido(campo, v));
}

List<Object?> _lista(Map<String, dynamic> j, String campo, String ctx, {bool obrigatorio = false}) {
  final v = j[campo];
  if (v == null) {
    if (obrigatorio) _erro(ctx, "'$campo' ausente");
    return const [];
  }
  if (v is List) return v;
  _erro(ctx, "'$campo' não é uma lista");
}

List<ClimaHistoria> _climas(List<Object?> lista, String ctx, bool estrito) {
  final r = <ClimaHistoria>[];
  for (final v in lista) {
    final c = _achar(ClimaHistoria.values, v);
    if (c != null) {
      r.add(c);
    } else if (estrito) {
      _erro(ctx, "clima '$v' inválido");
    }
  }
  return r;
}

TextoBilingue _bilingue(Object? v, String ctx, bool estrito) {
  final j = _mapa(v, ctx);
  _chaves(j, const {'en', 'pt'}, ctx, estrito);
  return TextoBilingue(_texto(j, 'en', ctx), _texto(j, 'pt', ctx));
}

AtorEmCena _lerAtor(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'quem', 'pos', 'visivel', 'remoto', 'segura', 'emocao', 'noCarro'}, ctx, estrito);
  return AtorEmCena(
    quem: _texto(j, 'quem', ctx),
    pos: _enumEstrutural(PosicaoPalco.values, j, 'pos', ctx),
    visivel: _bool(j, 'visivel', true, ctx, estrito),
    remoto: _enumEstrutural(ViaRemota.values, j, 'remoto', ctx),
    segura: _enumOpc(PropHistoria.values, j, 'segura', ctx, estrito),
    emocao: _enum(Expressao.values, j, 'emocao', ctx, estrito, padrao: emocaoPadrao),
    noCarro: _bool(j, 'noCarro', false, ctx, estrito),
  );
}

ObjetoEmCena _lerObjeto(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'prop', 'pos', 'visivel'}, ctx, estrito);
  return ObjetoEmCena(
    prop: _enum(PropHistoria.values, j, 'prop', ctx, estrito),
    pos: _enum(PosicaoPalco.values, j, 'pos', ctx, true),
    visivel: _bool(j, 'visivel', true, ctx, estrito),
  );
}

ReacaoHistoria _lerReacao(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'quem', 'emocao', 'acao', 'efeito', 'segura'}, ctx, estrito);
  return ReacaoHistoria(
    quem: _texto(j, 'quem', ctx),
    emocao: _enumOpc(Expressao.values, j, 'emocao', ctx, estrito, padraoTolerante: emocaoPadrao),
    acao: _enumOpc(AcaoAtor.values, j, 'acao', ctx, estrito, padraoTolerante: AcaoAtor.parado),
    efeito: _enumOpc(EfeitoHistoria.values, j, 'efeito', ctx, estrito),
    segura: _enumOpc(PropHistoria.values, j, 'segura', ctx, estrito),
  );
}

MovimentoObjeto _lerMovimento(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'prop', 'acao', 'pos', 'de'}, ctx, estrito);
  return MovimentoObjeto(
    prop: _enum(PropHistoria.values, j, 'prop', ctx, true),
    acao: _enum(AcaoObjeto.values, j, 'acao', ctx, true),
    pos: _enumEstrutural(PosicaoPalco.values, j, 'pos', ctx),
    de: _textoOpc(j, 'de', ctx, estrito),
  );
}

FalaHistoria _lerFala(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'quem', 'en', 'pt', 'pt_f', 'mudo', 'emocao', 'acao', 'alvo', 'para', 'camera', 'efeito', 'clima',
    'segura', 'cenario', 'hora', 'reacoes', 'objetos'}, ctx, estrito);
  final clima = j['clima'];
  final reacoes = _lista(j, 'reacoes', ctx);
  final objetos = _lista(j, 'objetos', ctx);
  return FalaHistoria(
    quem: _texto(j, 'quem', ctx),
    en: _textoOpc(j, 'en', ctx, estrito),
    pt: _textoOpc(j, 'pt', ctx, estrito),
    ptF: _textoOpc(j, 'pt_f', ctx, estrito),
    mudo: _bool(j, 'mudo', false, ctx, estrito),
    emocao: _enumOpc(Expressao.values, j, 'emocao', ctx, estrito, padraoTolerante: emocaoPadrao),
    acao: _enum(AcaoAtor.values, j, 'acao', ctx, estrito, padrao: AcaoAtor.parado),
    alvo: _textoOpc(j, 'alvo', ctx, estrito),
    para: _enumEstrutural(PosicaoPalco.values, j, 'para', ctx),
    camera: _enumOpc(CameraHistoria.values, j, 'camera', ctx, estrito, padraoTolerante: CameraHistoria.geral),
    efeito: _enumOpc(EfeitoHistoria.values, j, 'efeito', ctx, estrito),
    clima: clima == null ? null : _climas(_lista(j, 'clima', ctx), ctx, estrito),
    segura: _enumOpc(PropHistoria.values, j, 'segura', ctx, estrito),
    cenario: _enumEstrutural(CenarioHistoria.values, j, 'cenario', ctx),
    hora: _enumEstrutural(HoraHistoria.values, j, 'hora', ctx),
    reacoes: [
      for (var i = 0; i < reacoes.length; i++)
        _lerReacao(_mapa(reacoes[i], '$ctx reacoes[$i]'), estrito, '$ctx reacoes[$i]'),
    ],
    objetos: [
      for (var i = 0; i < objetos.length; i++)
        _lerMovimento(_mapa(objetos[i], '$ctx objetos[$i]'), estrito, '$ctx objetos[$i]'),
    ],
  );
}

CenaHistoria _lerCena(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'cenario', 'hora', 'clima', 'elenco', 'objetos', 'falas'}, ctx, estrito);
  final elenco = _lista(j, 'elenco', ctx);
  final objetos = _lista(j, 'objetos', ctx);
  final falas = _lista(j, 'falas', ctx, obrigatorio: true);
  return CenaHistoria(
    cenario: _enum(CenarioHistoria.values, j, 'cenario', ctx, true),
    hora: _enum(HoraHistoria.values, j, 'hora', ctx, true),
    clima: _climas(_lista(j, 'clima', ctx), ctx, estrito),
    elenco: [
      for (var i = 0; i < elenco.length; i++) _lerAtor(_mapa(elenco[i], '$ctx elenco[$i]'), estrito, '$ctx elenco[$i]'),
    ],
    objetos: [
      for (var i = 0; i < objetos.length; i++)
        _lerObjeto(_mapa(objetos[i], '$ctx objetos[$i]'), estrito, '$ctx objetos[$i]'),
    ],
    falas: [
      for (var i = 0; i < falas.length; i++)
        _lerFala(_mapa(falas[i], '$ctx fala ${i + 1}'), estrito, '$ctx fala ${i + 1}'),
    ],
  );
}

CapituloHistoria _lerCapitulo(Map<String, dynamic> j, bool estrito, String ctx) {
  _chaves(j, const {'pista', 'nivel', 'titulo', 'resumo', 'palavras', 'intro', 'fim', 'gancho'}, ctx, estrito);
  final pista = j['pista'];
  if (pista is! int) _erro(ctx, "'pista' ausente ou não é inteiro");
  final c = ctx.isEmpty ? 'cap $pista' : ctx;
  final nivelJson = j['nivel'];
  final nivel = nivelJson is String ? _achar(NivelIngles.values, nivelJson.toLowerCase()) : null;
  if (nivel == null || nivelJson != nivel.json) _erro(c, "nivel '$nivelJson' inválido");
  final palavras = _lista(j, 'palavras', c, obrigatorio: true);
  final intro = _lista(j, 'intro', c, obrigatorio: true);
  final fim = _lista(j, 'fim', c, obrigatorio: true);
  return CapituloHistoria(
    pista: pista,
    nivel: nivel,
    titulo: _bilingue(j['titulo'], '$c titulo', estrito),
    resumo: _texto(j, 'resumo', c),
    palavras: [
      for (var i = 0; i < palavras.length; i++)
        () {
          final pc = '$c palavras[$i]';
          final pj = _mapa(palavras[i], pc);
          _chaves(pj, const {'en', 'pt'}, pc, estrito);
          return PalavraChave(_texto(pj, 'en', pc), _texto(pj, 'pt', pc));
        }(),
    ],
    intro: [for (var i = 0; i < intro.length; i++) _lerCena(_mapa(intro[i], '$c intro[$i]'), estrito, '$c intro[$i]')],
    fim: [for (var i = 0; i < fim.length; i++) _lerCena(_mapa(fim[i], '$c fim[$i]'), estrito, '$c fim[$i]')],
    gancho: j['gancho'] == null ? null : _bilingue(j['gancho'], '$c gancho', estrito),
  );
}

// ───────────────────────────── modelo ─────────────────────────────

class TextoBilingue {
  final String en, pt;
  const TextoBilingue(this.en, this.pt);

  factory TextoBilingue.fromJson(Map<String, dynamic> j) => _bilingue(j, '', false);
}

/// Uma palavra do cartão "🔑 Words from the story" (não entra no baralho da corrida).
class PalavraChave {
  final String en, pt;
  const PalavraChave(this.en, this.pt);

  factory PalavraChave.fromJson(Map<String, dynamic> j) => PalavraChave(_texto(j, 'en', ''), _texto(j, 'pt', ''));
}

/// Um ator no começo da cena. Remoto ([remoto] != null) não ocupa posição: fala pelo rádio ou pelo celular de
/// quem está no palco.
class AtorEmCena {
  final String quem;
  final PosicaoPalco? pos;
  final bool visivel;
  final ViaRemota? remoto;
  final PropHistoria? segura;
  final Expressao emocao;
  final bool noCarro;

  const AtorEmCena({
    required this.quem,
    this.pos,
    this.visivel = true,
    this.remoto,
    this.segura,
    this.emocao = Expressao.neutro,
    this.noCarro = false,
  });

  bool get ehRemoto => remoto != null;

  factory AtorEmCena.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerAtor(j, estrito, '');
}

/// Um objeto no chão do palco no começo da cena.
class ObjetoEmCena {
  final PropHistoria prop;
  final PosicaoPalco pos;
  final bool visivel;

  const ObjetoEmCena({required this.prop, required this.pos, this.visivel = true});

  factory ObjetoEmCena.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerObjeto(j, estrito, '');
}

/// A reação de quem escuta (emoção, ação sem deslocamento, efeito, prop na mão).
class ReacaoHistoria {
  final String quem;
  final Expressao? emocao;
  final AcaoAtor? acao;
  final EfeitoHistoria? efeito;
  final PropHistoria? segura;

  const ReacaoHistoria({required this.quem, this.emocao, this.acao, this.efeito, this.segura});

  factory ReacaoHistoria.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerReacao(j, estrito, '');
}

/// Um objeto que se mexe no passo (aparece, some, entra, sai, passa, voa, roda, treme). Com [de], parte da mão
/// desse ator.
class MovimentoObjeto {
  final PropHistoria prop;
  final AcaoObjeto acao;
  final PosicaoPalco? pos;
  final String? de;

  const MovimentoObjeto({required this.prop, required this.acao, this.pos, this.de});

  factory MovimentoObjeto.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerMovimento(j, estrito, '');
}

/// Um passo da cena: uma fala (en/pt) ou um passo MUDO (só ação/efeito/reação).
class FalaHistoria {
  final String quem;
  final String? en, pt, ptF;
  final bool mudo;
  final Expressao? emocao;
  final AcaoAtor acao;
  final String? alvo;
  final PosicaoPalco? para;
  final CameraHistoria? camera;
  final EfeitoHistoria? efeito;
  final List<ClimaHistoria>? clima;
  final PropHistoria? segura;
  final CenarioHistoria? cenario;
  final HoraHistoria? hora;
  final List<ReacaoHistoria> reacoes;
  final List<MovimentoObjeto> objetos;

  const FalaHistoria({
    required this.quem,
    this.en,
    this.pt,
    this.ptF,
    this.mudo = false,
    this.emocao,
    this.acao = AcaoAtor.parado,
    this.alvo,
    this.para,
    this.camera,
    this.efeito,
    this.clima,
    this.segura,
    this.cenario,
    this.hora,
    this.reacoes = const [],
    this.objetos = const [],
  });

  bool get ehNarrador => quem == narrador;

  /// Palavras do `en` (tokens separados por espaço; contração = 1). Passo mudo → 0.
  int get palavras {
    final t = en?.trim() ?? '';
    if (mudo || t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  factory FalaHistoria.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerFala(j, estrito, '');
}

class CenaHistoria {
  final CenarioHistoria cenario;
  final HoraHistoria hora;
  final List<ClimaHistoria> clima;
  final List<AtorEmCena> elenco;
  final List<ObjetoEmCena> objetos;
  final List<FalaHistoria> falas;

  const CenaHistoria({
    required this.cenario,
    required this.hora,
    this.clima = const [],
    this.elenco = const [],
    this.objetos = const [],
    required this.falas,
  });

  factory CenaHistoria.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerCena(j, estrito, '');
}

class CapituloHistoria {
  final int pista;
  final NivelIngles nivel;
  final TextoBilingue titulo;

  /// Resumo em pt (o "📜 Resumo até aqui" da galeria).
  final String resumo;
  final List<PalavraChave> palavras;
  final List<CenaHistoria> intro, fim;

  /// "To be continued…" (capítulos 1–29; o 30 não tem).
  final TextoBilingue? gancho;

  const CapituloHistoria({
    required this.pista,
    required this.nivel,
    required this.titulo,
    required this.resumo,
    required this.palavras,
    required this.intro,
    required this.fim,
    this.gancho,
  });

  List<CenaHistoria> parte(ParteDoCapitulo p) => p == ParteDoCapitulo.intro ? intro : fim;

  Iterable<FalaHistoria> get todasAsFalas sync* {
    for (final c in intro) {
      yield* c.falas;
    }
    for (final c in fim) {
      yield* c.falas;
    }
  }

  factory CapituloHistoria.fromJson(Map<String, dynamic> j, {bool estrito = true}) => _lerCapitulo(j, estrito, '');
}

class HistoriaTurismo {
  final TextoBilingue titulo;

  /// Ordenados por pista.
  final List<CapituloHistoria> capitulos;

  const HistoriaTurismo(this.titulo, this.capitulos);

  static const _tituloPadrao = TextoBilingue('The Golden Wheel', 'A Roda de Ouro');
  static const _faixaDaParte = {'a': (1, 10), 'b': (11, 20), 'c': (21, 30)};

  CapituloHistoria? capitulo(int pista) {
    for (final c in capitulos) {
      if (c.pista == pista) return c;
    }
    return null;
  }

  /// Junta a/b/c. estrito=true: qualquer erro → FormatException clara ("cap 3 intro[0] fala 2: emocao 'happy' inválida").
  /// estrito=false (app): capítulo com erro é descartado (aviso?.call(motivo)); enum desconhecido → default.
  factory HistoriaTurismo.dasPartes(List<Map<String, dynamic>> partes,
      {bool estrito = true, void Function(String motivo)? aviso}) {
    TextoBilingue? titulo;
    final porPista = <int, CapituloHistoria>{};
    void falha(String ctx, String msg) {
      if (estrito) _erro(ctx, msg);
      aviso?.call('$ctx: $msg');
    }

    for (var p = 0; p < partes.length; p++) {
      final j = partes[p];
      final nomeParte = j['parte'];
      final ctx = 'parte ${nomeParte is String ? nomeParte : '#${p + 1}'}';
      try {
        _chaves(j, const {'versao', 'parte', 'titulo', 'capitulos'}, ctx, estrito);
        if (j['versao'] != 2) falha(ctx, "versao '${j['versao']}' (esperava 2)");
        final faixa = _faixaDaParte[nomeParte];
        if (faixa == null) falha(ctx, "parte '$nomeParte' inválida (a, b ou c)");
        final t = _bilingue(j['titulo'], '$ctx titulo', estrito);
        if (titulo == null) {
          titulo = t;
        } else if (titulo.en != t.en || titulo.pt != t.pt) {
          falha(ctx, 'titulo diferente das outras partes');
        }
        final caps = _lista(j, 'capitulos', ctx, obrigatorio: true);
        for (var i = 0; i < caps.length; i++) {
          final bruto = caps[i];
          final pista = bruto is Map ? bruto['pista'] : null;
          final cctx = pista is int ? 'cap $pista' : '$ctx capitulos[$i]';
          try {
            final cap = _lerCapitulo(_mapa(bruto, cctx), estrito, cctx);
            if (faixa != null && (cap.pista < faixa.$1 || cap.pista > faixa.$2)) {
              falha(cctx, 'fora da faixa da $ctx (${faixa.$1}–${faixa.$2})');
            }
            if (porPista.containsKey(cap.pista)) {
              falha(cctx, 'capítulo repetido');
              continue;
            }
            porPista[cap.pista] = cap;
          } on FormatException catch (e) {
            if (estrito) rethrow;
            aviso?.call('capítulo descartado: ${e.message}');
          }
        }
      } on FormatException catch (e) {
        if (estrito) rethrow;
        aviso?.call('parte descartada: ${e.message}');
      }
    }
    final ordenados = porPista.values.toList()..sort((a, b) => a.pista.compareTo(b.pista));
    return HistoriaTurismo(titulo ?? _tituloPadrao, ordenados);
  }

  /// [] = ok. Mensagens "cap 7 intro[1] fala 3: …". Usa SimulacaoCena. Regras: seção 11.4.
  /// [totalPistas] = quantos capítulos a história tem de cobrir (1..totalPistas, uma vez cada).
  List<String> validar({int totalPistas = 30}) {
    final erros = <String>[];
    // V-arquivo
    final contagem = <int, int>{};
    for (final c in capitulos) {
      contagem[c.pista] = (contagem[c.pista] ?? 0) + 1;
    }
    for (var n = 1; n <= totalPistas; n++) {
      final k = contagem[n] ?? 0;
      if (k == 0) erros.add('cap $n: ausente');
      if (k > 1) erros.add('cap $n: aparece $k vezes');
    }
    for (final n in contagem.keys) {
      if (n < 1 || n > totalPistas) erros.add('cap $n: fora de 1..$totalPistas');
    }
    for (var i = 1; i < capitulos.length; i++) {
      if (capitulos[i].pista <= capitulos[i - 1].pista) {
        erros.add('cap ${capitulos[i].pista}: fora de ordem');
        break;
      }
    }
    for (final c in capitulos) {
      _validarCapitulo(c, erros);
    }
    return erros;
  }
}

// ───────────────────────────── validação ─────────────────────────────

final _reFimDeFrase = RegExp(r'[.!?…]$');
final _reGiria = RegExp(r'\b(gonna|wanna|kinda)\b', caseSensitive: false);
final _reTermos = [
  for (final t in termosProibidos)
    (t, RegExp('(?<![\\p{L}\\p{N}])${RegExp.escape(t)}(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true)),
];

NivelIngles _nivelDaPista(int pista) => pista <= 8
    ? NivelIngles.a1
    : pista <= 16
        ? NivelIngles.a2
        : pista <= 24
            ? NivelIngles.b1
            : NivelIngles.b2;

void _validarTexto(String ctx, String? en, String? pt, String? ptF, List<String> erros, {int? maxPalavras}) {
  final e = en?.trim() ?? '';
  if (e.isEmpty) {
    erros.add('$ctx: en vazio');
  } else {
    if (!_reFimDeFrase.hasMatch(e)) erros.add("$ctx: en tem de terminar com . ! ? ou … ('$e')");
    if (e.contains('...') || e.contains('—') || e.contains('–') || e.contains('"')) {
      erros.add("$ctx: pontuação proibida no en (... — – ou aspas duplas) ('$e')");
    }
    if (e.runes.any((r) => r > 127 && r != 0x2026)) erros.add("$ctx: en só em ASCII, sem acento nem emoji ('$e')");
    if (_reGiria.hasMatch(e)) erros.add("$ctx: gonna/wanna/kinda são proibidos ('$e')");
    if (maxPalavras != null) {
      final n = e.split(RegExp(r'\s+')).length;
      if (n > maxPalavras) erros.add("$ctx: $n palavras no en (máx. $maxPalavras) ('$e')");
    }
  }
  if ((pt?.trim() ?? '').isEmpty) erros.add('$ctx: pt vazio');
  if (ptF != null && ptF.trim().isEmpty) erros.add('$ctx: pt_f vazio');
  for (final (termo, re) in _reTermos) {
    for (final s in [en, pt, ptF]) {
      if (s != null && re.hasMatch(s)) {
        erros.add("$ctx: termo proibido '$termo' ('$s')");
        break;
      }
    }
  }
}

void _validarCapitulo(CapituloHistoria cap, List<String> erros) {
  final c = 'cap ${cap.pista}';
  final mundo = cenarioDaPista[cap.pista];
  if (mundo == null) {
    erros.add('$c: pista fora de 1..30');
    return;
  }
  // V-capítulo
  final nivel = _nivelDaPista(cap.pista);
  if (cap.nivel != nivel) erros.add('$c: nivel ${cap.nivel.json} (esperava ${nivel.json})');
  final tituloEn = _titulosEn[cap.pista - 1];
  if (cap.titulo.en != tituloEn) erros.add("$c: titulo '${cap.titulo.en}' (esperava '$tituloEn')");
  if (cap.titulo.pt.trim().isEmpty) erros.add('$c: titulo sem pt');
  final r = cap.resumo.trim().length;
  if (r < 20 || r > 200) erros.add('$c: resumo com $r caracteres (20–200)');
  if (cap.palavras.length < 3 || cap.palavras.length > 6) {
    erros.add('$c: ${cap.palavras.length} palavras (3–6)');
  }
  final ens = <String>{};
  for (final p in cap.palavras) {
    if (p.en.trim().isEmpty || p.pt.trim().isEmpty) erros.add('$c: palavra sem en/pt');
    for (final w in p.en.split(RegExp(r'\s+'))) {
      if (w != w.toLowerCase() && !_nomesProprios.contains(w)) erros.add("$c: palavra '${p.en}' fora de minúsculas");
    }
    ens.add(p.en.trim().toLowerCase());
  }
  for (final (a, b) in paresDeInterferencia) {
    if (ens.contains(a) && ens.contains(b)) erros.add('$c: par de interferência $a/$b nas palavras');
  }
  if (cap.intro.isEmpty || cap.intro.length > 3) erros.add('$c: intro com ${cap.intro.length} cenas (1–3)');
  final maxFim = cap.pista == 30 ? 4 : 2;
  if (cap.fim.isEmpty || cap.fim.length > maxFim) erros.add('$c: fim com ${cap.fim.length} cenas (1–$maxFim)');
  if (cap.pista < 30 && cap.gancho == null) erros.add('$c: gancho obrigatório');
  if (cap.pista == 30 && cap.gancho != null) erros.add('$c: o capítulo 30 não tem gancho');
  final g = cap.gancho;
  if (g != null) _validarTexto('$c gancho', g.en, g.pt, null, erros);

  var mundoOk = false;
  for (final parte in ParteDoCapitulo.values) {
    final cenas = cap.parte(parte);
    var comTexto = 0;
    for (var i = 0; i < cenas.length; i++) {
      final linha = _validarCena('$c ${parte.name}[$i]', cenas[i], cap, nivel, erros);
      comTexto += cenas[i].falas.where((f) => !f.mudo).length;
      // V-mundo: o cenário efetivo da 1ª fala (depois da troca do próprio passo) ou da última.
      if (parte == ParteDoCapitulo.intro && linha.length > 1) {
        if (i == 0 && linha[1].cenario == mundo) mundoOk = true;
        if (i == cenas.length - 1 && linha.last.cenario == mundo) mundoOk = true;
      }
    }
    final (lo, hi) = parte == ParteDoCapitulo.intro
        ? nivel.faixaIntro
        : cap.pista == 30
            ? faixaFimFinal
            : nivel.faixaFim;
    if (comTexto < lo || comTexto > hi) erros.add('$c: ${parte.name} com $comTexto falas com texto ($lo–$hi)');
    // V-fim
    if (cenas.isNotEmpty && cenas.last.falas.isNotEmpty && cenas.last.falas.last.mudo) {
      erros.add('$c: a ${parte.name} termina num passo mudo (feche com uma fala)');
    }
  }
  if (!mundoOk) {
    erros.add("$c: V-mundo: nem a 1ª nem a última fala da intro acontecem em '${mundo.name}'");
  }
}

/// Valida a cena do capítulo e devolve a linha do tempo (estados antes de cada passo + o final).
List<EstadoCena> _validarCena(String ctx, CenaHistoria cena, CapituloHistoria cap, NivelIngles nivel,
        List<String> erros) =>
    validarCenaBase(ctx, cena, nivel, erros, personagens: personagensHistoria, porFala: (fc, f) {
      if ((f.quem == 'lucas' || f.quem == 'julia') && cap.pista < 15) {
        erros.add("$fc: '${f.quem}' só fala a partir do capítulo 15");
      }
    });

/// Valida a cena e devolve a linha do tempo (estados antes de cada passo + o final).
///
/// O núcleo comum do Turismo e das historinhas das lições (📺 Escutar assistindo): hora/clima, elenco
/// ([personagens] = quem pode estar no elenco; sem narrador, sem repetir, `pos` única, ≤ 5 presentes, ≤ 2
/// remotos, ≤ 4 objetos), os textos das falas ([validarTextos]; as lições puxam o texto do currículo e não
/// passam por aqui), ≤ 2 mudos seguidos, ≤ 3 mudos e toda a [SimulacaoCena.aplicar]. [porFala] roda em cada
/// passo com texto, logo depois da checagem do texto (o Turismo põe ali a regra lucas/julia).
/// Mensagens: "ctx rotuloPasso n: …" (o Turismo usa 'fala'; as lições, 'passo').
List<EstadoCena> validarCenaBase(String ctx, CenaHistoria cena, NivelIngles nivel, List<String> erros, {
  required Set<String> personagens,
  bool validarTextos = true,
  void Function(String ctxFala, FalaHistoria f)? porFala,
  String rotuloPasso = 'fala',
}) {
  // V-hora/clima
  if (!horasPermitidas(cena.cenario).contains(cena.hora)) {
    erros.add("$ctx: hora '${cena.hora.name}' não combina com '${cena.cenario.name}'");
  }
  if (cena.clima.toSet().length != cena.clima.length) erros.add('$ctx: clima repetido');
  for (final cl in cena.clima) {
    if (!climaPermitido(cl, cena.cenario, cena.hora)) {
      erros.add("$ctx: clima '${cl.name}' não combina com '${cena.cenario.name}'/'${cena.hora.name}'");
    }
  }
  // V-elenco
  final ids = <String>{};
  var presentes = 0, remotos = 0;
  final posicoes = <PosicaoPalco>{};
  for (final a in cena.elenco) {
    if (a.quem == narrador) {
      erros.add('$ctx: o narrador não entra no elenco');
    } else if (!personagens.contains(a.quem)) {
      erros.add("$ctx: personagem '${a.quem}' desconhecido");
    }
    if (!ids.add(a.quem)) erros.add("$ctx: '${a.quem}' repetido no elenco");
    if (a.segura == PropHistoria.nada) erros.add("$ctx: '${a.quem}' com segura 'nada' no elenco");
    if (a.ehRemoto) {
      remotos++;
      if (a.pos != null) erros.add("$ctx: '${a.quem}' é remoto e não tem pos");
    } else {
      presentes++;
      final p = a.pos;
      if (p == null) {
        erros.add("$ctx: '${a.quem}' sem pos");
      } else if (!posicoes.add(p)) {
        erros.add("$ctx: posição inicial '${p.name}' repetida");
      }
    }
  }
  if (presentes > 5) erros.add('$ctx: $presentes atores presentes (máx. 5)');
  if (remotos > 2) erros.add('$ctx: $remotos remotos (máx. 2)');
  if (cena.objetos.length > 4) erros.add('$ctx: ${cena.objetos.length} objetos (máx. 4)');
  final posObj = <PosicaoPalco>{};
  for (final o in cena.objetos) {
    if (o.prop == PropHistoria.nada) erros.add("$ctx: objeto 'nada'");
    if (!posObj.add(o.pos)) erros.add("$ctx: dois objetos em '${o.pos.name}'");
  }
  if (cena.falas.isEmpty) {
    erros.add('$ctx: cena sem falas');
    return [EstadoCena.inicial(cena)];
  }
  // passos
  var mudas = 0, seguidas = 0;
  final linha = <EstadoCena>[EstadoCena.inicial(cena)];
  for (var i = 0; i < cena.falas.length; i++) {
    final f = cena.falas[i];
    final fc = '$ctx $rotuloPasso ${i + 1}';
    if (f.mudo) {
      mudas++;
      seguidas++;
      if (seguidas == 3) erros.add('$fc: mais de 2 passos mudos seguidos');
    } else {
      seguidas = 0;
      if (validarTextos && (f.en != null || f.pt != null)) {
        _validarTexto(fc, f.en, f.pt, f.ptF, erros, maxPalavras: nivel.maxPalavras);
      }
      porFala?.call(fc, f);
    }
    final (depois, errosDoPasso) = SimulacaoCena.aplicar(linha.last, f);
    for (final e in errosDoPasso) {
      erros.add('$fc: $e');
    }
    linha.add(depois);
  }
  if (mudas > 3) erros.add('$ctx: $mudas passos mudos (máx. 3)');
  return linha;
}
