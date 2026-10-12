import 'package:equatable/equatable.dart';

import 'srs.dart';

/// Conferir a tradução que a pessoa ESCREVEU no cartão (o "digitar a resposta" do Anki).
/// Uma tradução tem várias formas certas, então não exige letra por letra: compara palavra
/// por palavra, ignora maiúscula, acento e pontuação, perdoa um errinho de digitação e não
/// liga para a ordem das palavras. O resultado marca o que acertou, o que faltou e o que
/// sobrou — e SUGERE uma nota, que a pessoa pode trocar.

/// Um pedaço do texto: uma palavra (com [acerto]) ou o que há entre as palavras
/// (espaço, pontuação: [acerto] null).
class Segmento extends Equatable {
  final String texto;

  /// Palavra: acertou (true) ou não (false). Pontuação/espaço: null.
  final bool? acerto;
  const Segmento(this.texto, [this.acerto]);

  @override
  List<Object?> get props => [texto, acerto];
}

class ComparacaoResposta extends Equatable {
  /// A resposta do cartão, marcando as palavras que a pessoa NÃO escreveu (acerto false).
  final List<Segmento> esperada;

  /// O que a pessoa escreveu, marcando as palavras que não estão na resposta (acerto false).
  final List<Segmento> digitada;

  /// Quantas palavras da resposta foram escritas (0–1) e quantas das escritas estavam certas (0–1).
  final double cobertura;
  final double precisao;

  /// Escreveu exatamente a resposta (sem contar maiúscula, acento e pontuação).
  final bool exata;

  /// A nota que combina com o resultado (errei, difícil ou bom — "fácil" só a pessoa escolhe).
  final Rating sugerida;

  const ComparacaoResposta({
    required this.esperada,
    required this.digitada,
    required this.cobertura,
    required this.precisao,
    required this.exata,
    required this.sugerida,
  });

  /// Palavras da resposta que a pessoa acertou / total.
  int get acertadas => esperada.where((s) => s.acerto == true).length;
  int get totalEsperadas => esperada.where((s) => s.acerto != null).length;

  @override
  List<Object?> get props => [esperada, digitada, cobertura, precisao, exata, sugerida];
}

/// Confere [digitada] com [esperada] (as duas em português).
ComparacaoResposta compararResposta(String esperada, String digitada) {
  final e = _palavras(esperada), d = _palavras(digitada);
  // alinhamento por maior subsequência comum (a ordem pesa pouco: o que casa conta)
  final casou = _casar(e, d);
  final eOk = List<bool>.filled(e.length, false), dOk = List<bool>.filled(d.length, false);
  for (final (i, j) in casou) {
    eOk[i] = true;
    dOk[j] = true;
  }
  // palavras fora da ordem também contam: o que sobrou de cada lado tenta casar com o outro
  for (var j = 0; j < d.length; j++) {
    if (dOk[j]) continue;
    for (var i = 0; i < e.length; i++) {
      if (!eOk[i] && _iguais(e[i].norm, d[j].norm)) {
        eOk[i] = true;
        dOk[j] = true;
        break;
      }
    }
  }
  final certas = eOk.where((x) => x).length;
  final cobertura = e.isEmpty ? 0.0 : certas / e.length;
  final precisao = d.isEmpty ? 0.0 : dOk.where((x) => x).length / d.length;
  final exata = e.isNotEmpty && e.length == d.length && casou.length == e.length && e.indexed.every((p) => p.$2.norm == d[p.$1].norm);

  final Rating sugerida;
  if (d.isEmpty) {
    sugerida = Rating.again;
  } else if (exata || (cobertura >= .85 && precisao >= .75)) {
    sugerida = Rating.good;
  } else if (cobertura >= .6 && precisao >= .5) {
    sugerida = Rating.hard;
  } else {
    sugerida = Rating.again;
  }
  return ComparacaoResposta(
    esperada: _segmentos(esperada, e, eOk),
    digitada: _segmentos(digitada, d, dOk),
    cobertura: cobertura,
    precisao: precisao,
    exata: exata,
    sugerida: sugerida,
  );
}

class _Palavra {
  final int ini, fim;
  final String norm;
  const _Palavra(this.ini, this.fim, this.norm);
}

final _unidade = RegExp(r'[\p{L}\p{N}]+', unicode: true);

List<_Palavra> _palavras(String s) =>
    [for (final m in _unidade.allMatches(s)) _Palavra(m.start, m.end, _sem(m[0]!))];

/// Minúscula e sem acento (á→a, ç→c, ñ→n…).
String _sem(String palavra) {
  final b = StringBuffer();
  for (final r in palavra.toLowerCase().runes) {
    b.write(_acentos[r] ?? String.fromCharCode(r));
  }
  return b.toString();
}

final _acentos = () {
  const grupos = {
    'a': 'àáâãäåā',
    'c': 'çć',
    'e': 'èéêëē',
    'i': 'ìíîïī',
    'n': 'ñ',
    'o': 'òóôõöō',
    'u': 'ùúûüū',
    'y': 'ýÿ',
  };
  final m = <int, String>{};
  grupos.forEach((base, letras) {
    for (final r in letras.runes) {
      m[r] = base;
    }
  });
  return m;
}();

/// Duas palavras contam como a mesma: iguais, ou com um errinho de digitação (1 letra em
/// palavra de 5+ letras; 2 em palavra de 9+).
bool _iguais(String a, String b) {
  if (a == b) return true;
  final n = a.length < b.length ? a.length : b.length;
  if (n < 5) return false;
  final tolerancia = n >= 9 ? 2 : 1;
  if ((a.length - b.length).abs() > tolerancia) return false;
  return _distancia(a, b) <= tolerancia;
}

int _distancia(String a, String b) {
  var anterior = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final atual = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final custo = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final troca = [anterior[j] + 1, atual[j - 1] + 1, anterior[j - 1] + custo].reduce((x, y) => x < y ? x : y);
      atual[j] = troca;
    }
    anterior = atual;
  }
  return anterior[b.length];
}

/// Pares (índice na esperada, índice na digitada) da maior subsequência comum.
List<(int, int)> _casar(List<_Palavra> e, List<_Palavra> d) {
  final t = List.generate(e.length + 1, (_) => List<int>.filled(d.length + 1, 0));
  for (var i = e.length - 1; i >= 0; i--) {
    for (var j = d.length - 1; j >= 0; j--) {
      t[i][j] = _iguais(e[i].norm, d[j].norm) ? t[i + 1][j + 1] + 1 : (t[i + 1][j] > t[i][j + 1] ? t[i + 1][j] : t[i][j + 1]);
    }
  }
  final r = <(int, int)>[];
  var i = 0, j = 0;
  while (i < e.length && j < d.length) {
    if (_iguais(e[i].norm, d[j].norm)) {
      r.add((i, j));
      i++;
      j++;
    } else if (t[i + 1][j] >= t[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return r;
}

/// O texto original em pedaços: cada palavra com o acerto dela e o que há entre as palavras como veio.
List<Segmento> _segmentos(String original, List<_Palavra> palavras, List<bool> ok) {
  final r = <Segmento>[];
  var pos = 0;
  for (var i = 0; i < palavras.length; i++) {
    final p = palavras[i];
    if (p.ini > pos) r.add(Segmento(original.substring(pos, p.ini)));
    r.add(Segmento(original.substring(p.ini, p.fim), ok[i]));
    pos = p.fim;
  }
  if (pos < original.length) r.add(Segmento(original.substring(pos)));
  return r;
}
