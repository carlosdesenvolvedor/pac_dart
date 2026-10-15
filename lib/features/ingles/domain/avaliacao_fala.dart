import 'alternativas.dart';
import 'avaliacao.dart';

/// Confere o que a pessoa FALOU (ou ditou pelo teclado do celular) contra a
/// frase do curso. O reconhecedor de voz devolve texto sem a grafia da
/// frase — "i'm" ou "I am", "7:30" ou "seven thirty", "two" por "to" — e
/// acerta o que o modelo de linguagem acha provável, não o que foi dito. Por
/// isso a conferência é por PALAVRA e tolerante com o que a voz não
/// distingue: caixa e pontuação não contam, contração e forma plena valem
/// (I'm = I am), número por extenso vale pelo algarismo, homófonos
/// (to/too/two) valem, e uma letra a mais ou a menos numa palavra longa
/// (o ouvido do reconhecedor) também. NOMES (palavra com inicial maiúscula:
/// Ana, Sarah, Lucas, cidades) valem pelo SOM: o reconhecedor escreve o que
/// conhece — "Ana" sai "Anna" ou "Hannah" — e quem fala não tem como acertar
/// a grafia.
class AvaliacaoFala {
  /// Uma entrada por palavra da frase ([palavrasDe]): saiu dita?
  final List<bool> palavrasOk;

  /// As palavras que o reconhecedor ouviu, na ordem (para mostrar).
  final List<String> ouvidas;

  /// Uma por palavra ouvida: casou com alguma da frase? (as que sobram são
  /// "a mais": não reprovam, só aparecem.)
  final List<bool> ouvidaCasou;

  const AvaliacaoFala({required this.palavrasOk, required this.ouvidas, required this.ouvidaCasou});

  int get palavras => palavrasOk.length;
  int get acertos => palavrasOk.where((b) => b).length;

  /// Todas as palavras da frase foram ditas.
  bool get perfeita => palavras > 0 && acertos == palavras;

  /// O reconhecedor não ouviu palavra nenhuma.
  bool get nada => ouvidas.isEmpty;

  /// Índices das palavras da frase que não saíram (para sublinhar).
  Set<int> get erradas => {
        for (var i = 0; i < palavrasOk.length; i++)
          if (!palavrasOk[i]) i,
      };

  /// As palavras ouvidas que não são da frase.
  List<String> get aMais => [
        for (var i = 0; i < ouvidas.length; i++)
          if (!ouvidaCasou[i]) ouvidas[i],
      ];
}

/// Confere [frase] com o que foi falado. [ditos] são as hipóteses do
/// reconhecedor (a mais provável primeiro, até umas cinco): vale a que mais
/// palavras acerta. A forma contraída/plena é aceita sozinha (I'm ↔ I am) e
/// as [alternativas] declaradas pelo autor também.
AvaliacaoFala avaliarFala(String frase, List<String> ditos, {List<String> alternativas = const []}) {
  final esperadas = _tokensDaFrase(frase);
  final total = palavrasDe(frase).length;
  AvaliacaoFala? melhor;
  for (final dito in ditos) {
    final a = _avaliarUma(esperadas, total, dito);
    if (melhor == null || a.acertos > melhor.acertos) melhor = a;
    if (a.perfeita) break;
  }
  melhor ??= AvaliacaoFala(palavrasOk: List.filled(total, false), ouvidas: const [], ouvidaCasou: const []);
  if (melhor.perfeita || alternativas.isEmpty) return melhor;
  // uma forma que o autor aceita (alt:) também vale por inteiro
  for (final alt in alternativas) {
    final tokensAlt = _tokensDaFrase(alt);
    final totalAlt = palavrasDe(alt).length;
    for (final dito in ditos) {
      final a = _avaliarUma(tokensAlt, totalAlt, dito);
      if (a.perfeita) {
        return AvaliacaoFala(
          palavrasOk: List.filled(total, true),
          ouvidas: a.ouvidas,
          ouvidaCasou: a.ouvidaCasou,
        );
      }
    }
  }
  return melhor;
}

// ── tokens ──────────────────────────────────────────────────────────

class _Tok {
  final String t;

  /// A palavra da frase de onde veio (um número vira várias palavras).
  final int dono;

  /// Nome próprio (inicial maiúscula): confere pelo som, não pela grafia.
  final bool nome;
  const _Tok(this.t, this.dono, {this.nome = false});
}

final _reFalada = RegExp(r"[A-Za-z0-9]+(?:['’‘´`ʼ][A-Za-z0-9]+)*");

String _semCurvas(String s) => s.replaceAll(RegExp(r"['’‘´`ʼ]"), "'").toLowerCase();

List<_Tok> _tokensDaFrase(String frase) {
  final r = <_Tok>[];
  var w = 0;
  for (final p in palavrasDe(frase)) {
    final bruta = frase.substring(p.ini, p.fim);
    final nome = _pareceNome(bruta);
    for (final parte in _semCurvas(bruta).split('-')) {
      for (final t in _expandir(parte)) {
        r.add(_Tok(t, w, nome: nome));
      }
    }
    w++;
  }
  return r;
}

/// Inicial maiúscula = nome (Ana, Sarah, Chicago, Friday). O "I" e as
/// contrações dele (I'm, I'll…) são maiúsculos mas não são nome.
bool _pareceNome(String palavra) {
  if (palavra.isEmpty) return false;
  final c = palavra[0];
  if (c == c.toLowerCase() || c != c.toUpperCase()) return false;
  return !RegExp(r"^I(['’](m|ll|ve|d))?$").hasMatch(palavra);
}

/// O som de um nome como o reconhecedor o escreveria: "Ana", "Anna",
/// "Hannah" e "Ahna" dão a mesma chave; "Sarah" = "Sara"; "Lucas" = "Lukas".
/// Tira o h mudo, dobra as letras repetidas e junta c/k, ph/f, y final/i.
String _chaveDeNome(String palavra) {
  var s = palavra.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  s = s.replaceAll('ph', 'f').replaceAll('ck', 'k').replaceAllMapped(RegExp(r'c(?!h)'), (_) => 'k');
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == 'h') {
      final antes = i > 0 ? s[i - 1] : '';
      if (antes.isNotEmpty && 'ckstgw'.contains(antes)) {
        b.write(c); // ch, sh, th, gh, wh
        continue;
      }
      if (i == 0 && s.length < 5) {
        b.write(c); // "Hi", "Hal": o h inicial de nome curto fica
        continue;
      }
      continue; // h mudo (Sarah, Hannah, Ahna)
    }
    b.write(c);
  }
  s = b.toString().replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  if (s.endsWith('y')) s = '${s.substring(0, s.length - 1)}i';
  return s;
}

bool _nomesParecidos(String a, String b) {
  final ka = _chaveDeNome(a), kb = _chaveDeNome(b);
  if (ka.isEmpty || kb.isEmpty) return false;
  if (ka == kb) return true;
  // nome mais longo aceita uma letra de diferença (Julia/Julie); o curto, nunca (Ben ≠ Ken)
  return ka.length >= 4 && kb.length >= 4 && (ka.length - kb.length).abs() <= 1 && _distancia(ka, kb) <= 1;
}

/// "25" → twenty five; "gonna" → going to; o resto fica como está.
List<String> _expandir(String palavra) {
  if (palavra.isEmpty) return const [];
  final n = int.tryParse(palavra);
  if (n != null && n < 1000 && palavra.length <= 3) return _extenso(n);
  return switch (palavra) {
    'gonna' => ['going', 'to'],
    'wanna' => ['want', 'to'],
    'gotta' => ['got', 'to'],
    'okay' => ['ok'],
    _ => [palavra],
  };
}

const _unidades = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
  'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
];
const _dezenas = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

List<String> _extenso(int n) {
  if (n < 20) return [_unidades[n]];
  if (n < 100) return [_dezenas[n ~/ 10], if (n % 10 != 0) _unidades[n % 10]];
  return [_unidades[n ~/ 100], 'hundred', if (n % 100 != 0) ..._extenso(n % 100)];
}

/// Palavras ouvidas, cada uma com os tokens em que se desdobra.
List<({String texto, List<String> tokens})> _ouvidasDe(String dito) => [
      for (final m in _reFalada.allMatches(dito))
        (
          texto: m.group(0)!,
          tokens: [for (final parte in _semCurvas(m.group(0)!).split('-')) ..._expandir(parte)],
        ),
    ];

// ── igualdade de palavras ───────────────────────────────────────────

/// Palavras que a voz não distingue — o reconhecedor escolhe uma delas pelo
/// contexto, e quem fala não tem como acertar "a certa".
final Map<String, int> _homofonos = () {
  const grupos = [
    ['to', 'too', 'two'],
    ['there', 'their', "they're"],
    ['your', "you're"],
    ['for', 'four', 'fore'],
    ['no', 'know'],
    ['right', 'write'],
    ['here', 'hear'],
    ['by', 'buy', 'bye'],
    ['its', "it's"],
    ['weather', 'whether'],
    ['one', 'won'],
    ['wait', 'weight'],
    ['where', 'wear'],
    ['new', 'knew'],
    ['would', 'wood'],
    ['see', 'sea'],
    ['be', 'bee'],
    ['son', 'sun'],
    ['meet', 'meat'],
    ['week', 'weak'],
    ['hour', 'our'],
    ['whole', 'hole'],
    ['sale', 'sail'],
    ['eight', 'ate'],
    ['which', 'witch'],
    ['mail', 'male'],
    ['made', 'maid'],
    ['piece', 'peace'],
    ['allowed', 'aloud'],
    ['dear', 'deer'],
    ['night', 'knight'],
    ['tail', 'tale'],
    ['plane', 'plain'],
    ['break', 'brake'],
    ['flower', 'flour'],
    ['cell', 'sell'],
    ['threw', 'through'],
  ];
  return {
    for (var g = 0; g < grupos.length; g++)
      for (final w in grupos[g]) w: g,
  };
}();

/// As formas plenas de uma contração ("i'm" → [i, am]); "can't" aceita as
/// duas grafias que o reconhecedor usa.
final Map<String, List<List<String>>> _contracoes = () {
  final m = <String, List<List<String>>>{};
  for (final e in contracoesConhecidas.entries) {
    m[e.key.toLowerCase()] = [e.value.toLowerCase().split(' ')];
  }
  m["can't"] = [
    ['cannot'],
    ['can', 'not'],
  ];
  // 's e 'd são ambíguas na digitação, mas na fala "he's" = he is/has e o
  // reconhecedor escreve as duas: aceita as duas
  m["he's"] = [['he', 'is'], ['he', 'has']];
  m["she's"] = [['she', 'is'], ['she', 'has']];
  m["it's"] = [['it', 'is'], ['it', 'has']];
  m["that's"] = [['that', 'is']];
  m["there's"] = [['there', 'is']];
  m["what's"] = [['what', 'is']];
  m["where's"] = [['where', 'is']];
  m["who's"] = [['who', 'is']];
  m["let's"] = [['let', 'us']];
  m["i'd"] = [['i', 'would'], ['i', 'had']];
  return m;
}();

bool _iguais(String a, String b) {
  if (a == b) return true;
  final g = _homofonos[a];
  if (g != null && g == _homofonos[b]) return true;
  // o ouvido do reconhecedor: uma letra a mais ou a menos numa palavra longa
  if (a.length >= 5 && b.length >= 5 && (a.length - b.length).abs() <= 1 && _distancia(a, b) <= 1) return true;
  return false;
}

int _distancia(String a, String b) {
  var ant = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final atual = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final troca = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = ant[j - 1] + troca;
      if (ant[j] + 1 < v) v = ant[j] + 1;
      if (atual[j - 1] + 1 < v) v = atual[j - 1] + 1;
      atual[j] = v;
    }
    ant = atual;
  }
  return ant[b.length];
}

// ── alinhamento ─────────────────────────────────────────────────────

AvaliacaoFala _avaliarUma(List<_Tok> esp, int totalPalavras, String dito) {
  final ouvidas = _ouvidasDe(dito);
  // tokens ouvidos, cada um sabendo de que palavra ouvida saiu
  final fal = <String>[];
  final donoFal = <int>[];
  for (var i = 0; i < ouvidas.length; i++) {
    for (final t in ouvidas[i].tokens) {
      fal.add(t);
      donoFal.add(i);
    }
  }
  final n = esp.length, m = fal.length;

  bool casa1(_Tok tok, String s) {
    final e = tok.t;
    if (_iguais(e, s)) return true;
    if (tok.nome && _nomesParecidos(e, s)) return true;
    for (final ex in _contracoes[e] ?? const <List<String>>[]) {
      if (ex.length == 1 && _iguais(ex[0], s)) return true;
    }
    for (final ex in _contracoes[s] ?? const <List<String>>[]) {
      if (ex.length == 1 && _iguais(ex[0], e)) return true;
    }
    return false;
  }

  // esperado contraído ("i'm") dito por extenso ("i am")
  bool casaExpandidoFalado(String e, String s1, String s2) {
    for (final ex in _contracoes[e] ?? const <List<String>>[]) {
      if (ex.length == 2 && _iguais(ex[0], s1) && _iguais(ex[1], s2)) return true;
    }
    return false;
  }

  // esperado por extenso ("i am") dito contraído ("i'm")
  bool casaFaladoContraido(String s, String e1, String e2) => casaExpandidoFalado(s, e1, e2);

  // custo[i][j]: melhor alinhamento dos i primeiros esperados com os j primeiros ouvidos
  final custo = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  final de = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0)); // 1 casa/troca, 2 pula esperado, 3 pula ouvido, 4 (1,2), 5 (2,1)
  for (var i = 1; i <= n; i++) {
    custo[i][0] = i;
    de[i][0] = 2;
  }
  for (var j = 1; j <= m; j++) {
    custo[0][j] = j;
    de[0][j] = 3;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final bate = casa1(esp[i - 1], fal[j - 1]);
      var melhor = custo[i - 1][j - 1] + (bate ? 0 : 1);
      var op = 1;
      if (custo[i - 1][j] + 1 < melhor) {
        melhor = custo[i - 1][j] + 1;
        op = 2;
      }
      if (custo[i][j - 1] + 1 < melhor) {
        melhor = custo[i][j - 1] + 1;
        op = 3;
      }
      if (j >= 2 && casaExpandidoFalado(esp[i - 1].t, fal[j - 2], fal[j - 1]) && custo[i - 1][j - 2] < melhor) {
        melhor = custo[i - 1][j - 2];
        op = 4;
      }
      if (i >= 2 && casaFaladoContraido(fal[j - 1], esp[i - 2].t, esp[i - 1].t) && custo[i - 2][j - 1] < melhor) {
        melhor = custo[i - 2][j - 1];
        op = 5;
      }
      custo[i][j] = melhor;
      de[i][j] = op;
    }
  }

  final espCasou = List<bool>.filled(n, false);
  final falCasou = List<bool>.filled(m, false);
  var i = n, j = m;
  while (i > 0 || j > 0) {
    switch (de[i][j]) {
      case 1:
        if (casa1(esp[i - 1], fal[j - 1])) {
          espCasou[i - 1] = true;
          falCasou[j - 1] = true;
        }
        i--;
        j--;
      case 2:
        i--;
      case 3:
        j--;
      case 4:
        espCasou[i - 1] = true;
        falCasou[j - 1] = true;
        falCasou[j - 2] = true;
        i--;
        j -= 2;
      default:
        espCasou[i - 1] = true;
        espCasou[i - 2] = true;
        falCasou[j - 1] = true;
        i -= 2;
        j--;
    }
  }

  // uma palavra da frase só vale se TODOS os seus tokens casaram
  final palavrasOk = List<bool>.filled(totalPalavras, true);
  final temToken = List<bool>.filled(totalPalavras, false);
  for (var k = 0; k < n; k++) {
    final d = esp[k].dono;
    if (d >= totalPalavras) continue;
    temToken[d] = true;
    if (!espCasou[k]) palavrasOk[d] = false;
  }
  for (var w = 0; w < totalPalavras; w++) {
    if (!temToken[w]) palavrasOk[w] = false;
  }
  final ouvidaCasou = List<bool>.filled(ouvidas.length, true);
  final temTokenOuvida = List<bool>.filled(ouvidas.length, false);
  for (var k = 0; k < m; k++) {
    temTokenOuvida[donoFal[k]] = true;
    if (!falCasou[k]) ouvidaCasou[donoFal[k]] = false;
  }
  for (var k = 0; k < ouvidas.length; k++) {
    if (!temTokenOuvida[k]) ouvidaCasou[k] = false;
  }
  return AvaliacaoFala(
    palavrasOk: palavrasOk,
    ouvidas: [for (final o in ouvidas) o.texto],
    ouvidaCasou: ouvidaCasou,
  );
}
