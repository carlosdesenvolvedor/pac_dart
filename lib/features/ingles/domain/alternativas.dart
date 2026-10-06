/// Formas equivalentes de uma frase aceitas na digitação de memória
/// (DESIGN §3.3): as contrações automáticas não ambíguas, nos dois sentidos,
/// e as alternativas que o autor declarou (`alt`). As ambíguas (`'s` = is,
/// has ou posse; `'d` = would ou had) não são automáticas, e "have" de posse
/// nunca é contraído (I've a car é britânico/estranho).
library;

const _contraidaParaPlena = {
  "I'm": 'I am',
  "can't": 'cannot',
  "won't": 'will not',
  "don't": 'do not',
  "doesn't": 'does not',
  "didn't": 'did not',
  "isn't": 'is not',
  "aren't": 'are not',
  "wasn't": 'was not',
  "weren't": 'were not',
  "haven't": 'have not',
  "hasn't": 'has not',
  "hadn't": 'had not',
  "wouldn't": 'would not',
  "couldn't": 'could not',
  "shouldn't": 'should not',
  "mustn't": 'must not',
  "you're": 'you are',
  "we're": 'we are',
  "they're": 'they are',
  "I've": 'I have',
  "you've": 'you have',
  "we've": 'we have',
  "they've": 'they have',
  "I'll": 'I will',
  "you'll": 'you will',
  "we'll": 'we will',
  "they'll": 'they will',
  "he'll": 'he will',
  "she'll": 'she will',
  "it'll": 'it will',
};

/// Plena → contraída só onde a contração é sempre natural (sem o "have").
const _plenaParaContraida = {
  'I am': "I'm",
  'cannot': "can't",
  'will not': "won't",
  'do not': "don't",
  'does not': "doesn't",
  'did not': "didn't",
  'is not': "isn't",
  'are not': "aren't",
  'was not': "wasn't",
  'were not': "weren't",
  'you are': "you're",
  'we are': "we're",
  'they are': "they're",
  'I will': "I'll",
  'you will': "you'll",
  'we will': "we'll",
  'they will': "they'll",
};

/// Máximo de variantes geradas (2^3 = três contrações na mesma frase).
const _maxTrocas = 3;

/// As outras formas aceitas de [frase] (sem ela mesma), na ordem: as
/// declaradas e depois as geradas.
List<String> alternativasDe(String frase, {List<String> declaradas = const []}) {
  // cada ocorrência trocável: posição, tamanho e o texto que entra no lugar
  final trocas = <({int ini, int fim, String por})>[];
  void procura(Map<String, String> tabela) {
    for (final e in tabela.entries) {
      final re = RegExp('(?<![A-Za-z\'])${RegExp.escape(e.key)}(?![A-Za-z\'])', caseSensitive: false);
      for (final m in re.allMatches(frase)) {
        if (trocas.any((t) => m.start < t.fim && t.ini < m.end)) continue;
        trocas.add((ini: m.start, fim: m.end, por: _comCaixa(m.group(0)!, e.value)));
      }
    }
  }

  procura(_contraidaParaPlena);
  procura(_plenaParaContraida);
  trocas.sort((a, b) => a.ini.compareTo(b.ini));
  final usadas = trocas.take(_maxTrocas).toList();
  final saida = <String>[...declaradas.where((d) => d != frase)];
  for (var mascara = 1; mascara < (1 << usadas.length); mascara++) {
    final b = StringBuffer();
    var pos = 0;
    for (var i = 0; i < usadas.length; i++) {
      if (mascara & (1 << i) == 0) continue;
      b.write(frase.substring(pos, usadas[i].ini));
      b.write(usadas[i].por);
      pos = usadas[i].fim;
    }
    b.write(frase.substring(pos));
    final alt = b.toString();
    if (alt != frase && !saida.contains(alt)) saida.add(alt);
  }
  return saida;
}

/// "Don't" → "Do not" (mantém a maiúscula do começo; "I" fica sempre "I").
String _comCaixa(String original, String novo) {
  if (original.isEmpty || novo.isEmpty) return novo;
  final maiuscula = original[0] == original[0].toUpperCase() && original[0] != original[0].toLowerCase();
  if (maiuscula && novo[0] != 'I') return novo[0].toUpperCase() + novo.substring(1);
  if (!maiuscula && novo[0] != 'I') return novo[0].toLowerCase() + novo.substring(1);
  return novo;
}
