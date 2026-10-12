import 'package:equatable/equatable.dart';

/// Do texto que a pessoa colou às frases de uma lição: simplifica o que o
/// teclado não escreve (aspas curvas, travessão, acento, emoji), separa em
/// frases (sem partir "Mr. Smith" nem "3.14") e quebra as compridas demais
/// — o curso inteiro é digitado, então cada frase tem que caber na cabeça.

/// Frases do curso passam de 25 palavras só no C1 (teto do validador).
const maxPalavrasPorFrase = 25;

/// Um texto colado vira, no máximo, tantas frases (o resto é cortado e a
/// tela avisa) — cada uma é traduzida e digitada 5 vezes.
const maxFrasesPorTexto = 150;

class TextoDividido extends Equatable {
  final List<String> frases;

  /// O texto tinha mais frases do que cabem ([maxFrasesPorTexto]).
  final bool cortado;

  /// Havia caracteres que o teclado não escreve (aspas curvas, acentos…):
  /// viraram letras simples.
  final bool simplificou;

  /// Quantas frases o texto tinha antes do corte.
  final int total;

  const TextoDividido({required this.frases, this.cortado = false, this.simplificou = false, this.total = 0});

  @override
  List<Object?> get props => [frases, cortado, simplificou, total];
}

/// Separa [bruto] em frases prontas para digitar (ASCII, sem repetidas).
TextoDividido dividirEmFrases(String bruto, {int maxFrases = maxFrasesPorTexto, int maxPalavras = maxPalavrasPorFrase}) {
  final simplificou = bruto.runes.any((r) => r > 0x7E && !_ehEspacoOuInvisivel(r));
  final limpo = simplificarParaDigitar(bruto);

  final frases = <String>[];
  final vistas = <String>{};
  for (final bloco in _blocos(limpo)) {
    for (final f in _frasesDoBloco(bloco)) {
      for (final parte in _quebrar(f, maxPalavras)) {
        final p = parte.trim();
        // sem nenhuma letra ("***", "12", "—") não é frase
        if (!RegExp(r'[A-Za-z]').hasMatch(p)) continue;
        if (vistas.add(p.toLowerCase())) frases.add(p);
      }
    }
  }
  return TextoDividido(
    frases: frases.take(maxFrases).toList(),
    cortado: frases.length > maxFrases,
    simplificou: simplificou,
    total: frases.length,
  );
}

/// Reparte [itens] em lições de até [porLicao], bem equilibradas (17 frases
/// viram 6+6+5, não 8+8+1).
List<List<T>> repartirEmLicoes<T>(List<T> itens, {int porLicao = 8}) {
  if (itens.isEmpty) return const [];
  final n = (itens.length / porLicao).ceil();
  final tam = (itens.length / n).ceil();
  return [for (var i = 0; i < itens.length; i += tam) itens.sublist(i, i + tam > itens.length ? itens.length : i + tam)];
}

/// Lições de até [porLicao] em sequência (8, 8, 1…): o que já está numa lição nunca muda
/// quando entram frases novas no fim.
List<List<T>> repartirEmSequencia<T>(List<T> itens, {int porLicao = 8}) => [
      for (var i = 0; i < itens.length; i += porLicao)
        itens.sublist(i, i + porLicao > itens.length ? itens.length : i + porLicao),
    ];

/// Um título curto a partir da 1ª frase ("Hi, I'm Ana. Nice to…" → "Hi, I'm Ana").
String tituloDaPrimeiraFrase(List<String> frases) {
  if (frases.isEmpty) return 'Meu texto';
  final palavras = frases.first.split(RegExp(r'\s+')).take(5).toList();
  var t = palavras.join(' ').replaceAll(RegExp(r'[\s.,;:!?"\x27()\-]+$'), '');
  if (t.isEmpty) return 'Meu texto';
  if (t.length > 36) t = '${t.substring(0, 35).trimRight()}…';
  return t[0].toUpperCase() + t.substring(1);
}

// ---------------------------------------------------------------- limpeza

bool _ehEspacoOuInvisivel(int r) =>
    r == 0xA0 || r == 0xAD || (r >= 0x2000 && r <= 0x200D) || r == 0x202F || r == 0x205F || r == 0x3000 || r == 0xFEFF;

final _acentos = () {
  const grupos = {
    'a': 'àáâãäåāăą',
    'c': 'çćč',
    'd': 'ďđ',
    'e': 'èéêëēěę',
    'g': 'ğ',
    'i': 'ìíîïī',
    'l': 'łľ',
    'n': 'ñńň',
    'o': 'òóôõöøōő',
    'r': 'ř',
    's': 'śšş',
    't': 'ťţ',
    'u': 'ùúûüūůű',
    'y': 'ýÿ',
    'z': 'žźż',
  };
  final m = <int, String>{};
  grupos.forEach((base, letras) {
    for (final r in letras.runes) {
      m[r] = base;
      m[String.fromCharCode(r).toUpperCase().runes.first] = base.toUpperCase();
    }
  });
  m[0xDF] = 'ss'; // ß
  m[0x153] = 'oe'; // œ
  m[0x152] = 'Oe';
  m[0xE6] = 'ae'; // æ
  m[0xC6] = 'Ae';
  // aspas e hífens tipográficos
  for (final r in '“”„«»'.runes) {
    m[r] = '"';
  }
  for (final r in '‘’‚‛′´`'.runes) {
    m[r] = "'";
  }
  for (final r in '‐‑‒−'.runes) {
    m[r] = '-';
  }
  m[0x2026] = '...'; // …
  return m;
}();

/// Troca o que não dá para digitar por letras e sinais comuns: aspas curvas
/// viram retas, travessão vira hífen, acento sai (café → cafe), emoji,
/// símbolos e links somem. Mantém as quebras de linha.
String simplificarParaDigitar(String s) {
  var t = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // 1990–2000 → 1990-2000; "palavra — palavra" → "palavra - palavra"
  t = t.replaceAllMapped(RegExp(r'(\d)\s*[–—―]\s*(\d)'), (m) => '${m[1]}-${m[2]}');
  t = t.replaceAll(RegExp(r'[ \t]*[–—―][ \t]*'), ' - ');
  t = t.replaceAll(RegExp(r'(https?://|www\.)\S+'), '');
  final b = StringBuffer();
  for (final r in t.runes) {
    if (r == 0x0A || r == 0x09 || (r >= 0x20 && r <= 0x7E)) {
      b.writeCharCode(r);
    } else if (_ehEspacoOuInvisivel(r)) {
      // espaço largo vira espaço; invisível some
      if (r == 0xA0 || r == 0x2002 || r == 0x2003 || r == 0x2009 || r == 0x202F || r == 0x3000 || r == 0x205F) {
        b.write(' ');
      }
    } else {
      final troca = _acentos[r];
      if (troca != null) b.write(troca);
    }
  }
  return b.toString();
}

// ----------------------------------------------------------------- frases

/// Marcadores de lista ("- ", "* ", "1. ", "2)") no começo da linha.
final _marcador = RegExp(r'^(?:[-*]|\d{1,2}[.)])\s+');

/// Parágrafos/linhas. Uma quebra de linha no meio da frase (texto copiado de
/// PDF ou de coluna estreita) junta as linhas; linha em branco, ponto final
/// ou a linha seguinte começando em maiúscula separam.
List<String> _blocos(String texto) {
  final blocos = <String>[];
  String? atual;
  for (final bruta in texto.split('\n')) {
    final linha = bruta.replaceAll(RegExp(r'\s+'), ' ').trim().replaceFirst(_marcador, '');
    if (linha.isEmpty) {
      if (atual != null) blocos.add(atual);
      atual = null;
      continue;
    }
    if (atual != null && _continua(atual, linha)) {
      atual = '$atual $linha';
    } else {
      if (atual != null) blocos.add(atual);
      atual = linha;
    }
  }
  if (atual != null) blocos.add(atual);
  return blocos;
}

bool _continua(String anterior, String proxima) =>
    !RegExp(r'[.!?:;]["\x27)\]]*$').hasMatch(anterior) && RegExp(r'^[a-z]').hasMatch(proxima);

/// Abreviações cujo ponto NÃO termina a frase.
const _abreviacoes = {
  'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'vs', 'inc', 'ltd', 'co', 'corp', 'mt', 'gen', 'col', 'lt', 'sgt',
  'capt', 'fig', 'approx', 'dept', 'est', 'vol', 'jan', 'feb', 'apr', 'jun', 'jul', 'aug', 'sep', 'sept', 'oct', 'nov',
  'dec', 'e.g', 'i.e', 'u.s', 'u.k', 'a.m', 'p.m', 'ph.d',
};

/// Fim de frase: . ! ? (com aspas/parêntese colados) seguido de espaço e
/// maiúscula, número ou aspas de abertura — ou do fim do bloco.
final _fimDeFrase = RegExp(r'''[.!?]+["')\]]*(?=\s+["'(\[]?[A-Z0-9]|\s*$)''');

List<String> _frasesDoBloco(String bloco) {
  final r = <String>[];
  var ini = 0;
  for (final m in _fimDeFrase.allMatches(bloco)) {
    final pontuacao = m[0]!;
    if (pontuacao.startsWith('.') && !pontuacao.startsWith('..')) {
      final antes = bloco.substring(ini, m.start);
      final palavra = RegExp(r'([A-Za-z][A-Za-z.]*)$').firstMatch(antes)?[1] ?? '';
      final minuscula = palavra.toLowerCase();
      // inicial de nome ("J. K. Rowling"); "I." e "A." costumam fechar a frase
      final inicial = palavra.length == 1 && palavra == palavra.toUpperCase() && palavra != 'I' && palavra != 'A';
      if ((inicial || _abreviacoes.contains(minuscula)) && m.end < bloco.length) continue;
    }
    final f = bloco.substring(ini, m.end).trim();
    if (f.isNotEmpty) r.add(f);
    ini = m.end;
  }
  final resto = bloco.substring(ini).trim();
  if (resto.isNotEmpty) r.add(resto);
  return r;
}

int _palavras(String s) => RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*").allMatches(s).length;

/// Frase comprida demais: corta em ; : , ou " - " onde as duas metades ficam
/// mais parecidas (ponto e vírgula e dois-pontos pesam mais que vírgula).
/// Sem lugar bom para cortar, deixa inteira.
List<String> _quebrar(String s, int max) {
  if (_palavras(s) <= max) return [s];
  int? melhor;
  var melhorNota = 1 << 30;
  late String esq, dir;
  for (final m in RegExp(r'[;:,]\s+|\s-\s').allMatches(s)) {
    final e = s.substring(0, m[0]!.trim() == '-' ? m.start : m.start + 1).trim();
    final d = s.substring(m.end).trim();
    final pe = _palavras(e), pd = _palavras(d);
    if (pe < 4 || pd < 4) continue;
    final forte = m[0]!.startsWith(';') || m[0]!.startsWith(':');
    final nota = (pe - pd).abs() - (forte ? 6 : 0);
    if (nota < melhorNota) {
      melhorNota = nota;
      melhor = m.start;
      esq = e;
      dir = d;
    }
  }
  if (melhor == null) return [s];
  return [..._quebrar(esq, max), ..._quebrar(dir, max)];
}
