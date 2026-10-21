/// Nota de uma voz do navegador para o curso (maior = melhor; -1 = não
/// serve). Ranking do dossiê 06 §A5: vozes neurais do Edge > Google do
/// Chrome > vozes aprimoradas da Apple > Samantha > o resto em inglês;
/// en-US antes de en-GB; descarta as "de brincadeira" e as quebradas.
///
/// [idioma] `pt` (a tradução do "🎧 Ouvir", FASE-8) pontua as vozes em português: neurais do Edge
/// (Francisca/Antonio) > Google português do Brasil > Luciana (Apple) > o resto; pt-BR antes de pt-PT.
int notaDaVoz(String nome, String lang, {bool local = false, String idioma = 'en'}) {
  final l = lang.toLowerCase().replaceAll('_', '-');
  if (!l.startsWith(idioma)) return -1;
  final n = nome.toLowerCase();
  if (n.contains('undefined')) return -1;
  for (final ruim in _ruins) {
    if (n.contains(ruim)) return 0;
  }
  if (idioma == 'pt') return _notaPt(n, l, local);
  if (idioma != 'en') return 30 + (local ? 5 : 0);
  var pontos = 30;
  if (RegExp(r'microsoft (ava|andrew|emma|brian|jenny|aria|guy|michelle|christopher|eric|roger|steffan)').hasMatch(n) &&
      n.contains('natural')) {
    pontos = 100;
  } else if (n.contains('natural') || n.contains('neural')) {
    pontos = 90;
  } else if (n.contains('google us english') || (n.contains('google') && l == 'en-us')) {
    pontos = 80;
  } else if (RegExp(r'\b(ava|zoe|evan|alex|nathan|allison|tom)\b').hasMatch(n) &&
      (n.contains('enhanced') || n.contains('premium') || !n.contains('compact'))) {
    pontos = 70;
  } else if (n.contains('samantha')) {
    pontos = 50;
  } else if (RegExp(r'\b(zira|david|mark)\b').hasMatch(n)) {
    pontos = 40;
  }
  if (l == 'en-us') pontos += 10;
  if (local) pontos += 5;
  return pontos;
}

int _notaPt(String n, String l, bool local) {
  var pontos = 30;
  if (RegExp(r'microsoft (francisca|antonio|thalita|brenda|donato|elza|fabio|giovanna|humberto|julio|leila|leticia|manuela|nicolau|valerio|yara)').hasMatch(n) &&
      n.contains('natural')) {
    pontos = 100;
  } else if (n.contains('natural') || n.contains('neural')) {
    pontos = 90;
  } else if (n.contains('google português do brasil') ||
      n.contains('google portugues do brasil') ||
      (n.contains('google') && l == 'pt-br')) {
    pontos = 80;
  } else if (RegExp(r'\bluciana\b').hasMatch(n) &&
      (n.contains('enhanced') || n.contains('premium') || !n.contains('compact'))) {
    pontos = 70;
  } else if (RegExp(r'\b(felipe|fernanda|joana|catarina)\b').hasMatch(n)) {
    pontos = 50;
  } else if (RegExp(r'\b(maria|daniel|heloisa)\b').hasMatch(n)) {
    pontos = 40;
  }
  if (l == 'pt-br') pontos += 10;
  if (local) pontos += 5;
  return pontos;
}

/// Vozes de efeito (macOS) e sintetizadores antigos que não servem de padrão.
const _ruins = [
  'eloquence', 'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles', 'cellos', 'good news', 'jester',
  'organ', 'superstar', 'trinoids', 'whisper', 'wobble', 'zarvox', 'fred', 'junior', 'ralph', 'kathy',
  'grandma', 'grandpa', 'rocko', 'shelley', 'flo', 'sandy', 'reed', 'eddy',
];
