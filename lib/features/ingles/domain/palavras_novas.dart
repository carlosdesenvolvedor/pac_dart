// "Palavras novas" do PAC·ENGLISH: as palavras que cada lição apresenta pela
// 1ª vez no curso (para treinar logo depois da lição) e o "pool" de palavras
// digitáveis de cada lição (o que os jogos do Arcade usam). Tudo derivado do
// currículo + dicionário embutido — nada é gravado, então o curso pode crescer
// sem migração. Dart puro.
import 'package:equatable/equatable.dart';

import '../../curso/domain/curriculo.dart';
import 'dicionario.dart';

/// Palavras de função (artigos, pronomes, auxiliares, preposições, conjunções):
/// aparecem em tudo e não são "palavra nova" de lição nenhuma. Extensão das
/// comuns das sanguessugas.
const Set<String> stopwordsEn = {
  // artigos, determinantes e quantificadores
  'a', 'an', 'the', 'this', 'that', 'these', 'those', 'some', 'any', 'each', 'every', 'all', 'both', 'more', 'much',
  'many', 'such', 'own', 'other', 'another',
  // pronomes
  'i', 'me', 'my', 'mine', 'you', 'your', 'yours', 'he', 'him', 'his', 'she', 'her', 'hers', 'it', 'its', 'we', 'us',
  'our', 'ours', 'they', 'them', 'their', 'theirs', 'myself', 'yourself', 'himself', 'herself', 'itself',
  'ourselves', 'themselves', 'who', 'whom', 'whose', 'which', 'what',
  // be / do / have e modais
  'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'do', 'does', 'did', 'have', 'has', 'had', 'can',
  'could', 'will', 'would', 'shall', 'should', 'may', 'might', 'must',
  // preposições e advérbios de ligação
  'of', 'to', 'in', 'on', 'at', 'by', 'for', 'with', 'from', 'into', 'onto', 'about', 'out', 'up', 'off', 'over',
  'than', 'then', 'there', 'here', 'just', 'very', 'too', 'also', 'not',
  // conjunções e interrogativas
  'and', 'or', 'but', 'nor', 'so', 'if', 'as', 'when', 'where', 'how', 'why',
};

final _reToken = RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*");
final _reNomeProprio = RegExp(r'\((nome|cidade|país|estado|sobrenome)\)');
final _reLema = RegExp(r"\((?:(?:passado|plural|comparativo|particípio|superlativo|possessivo)\s+)?de\s+([a-z][a-z'-]*)\)");
final _reSoletrada = RegExp(r'^([a-z]-)+[a-z]$');
final _reDigito = RegExp(r'[0-9]');
final _reDeJogo = RegExp(r'^[A-Za-z]{3,14}$');
final _rePontas = RegExp(r'^[^A-Za-z]+|[^A-Za-z]+$');

/// O sentido principal de um verbete do dicionário, curto para caber embaixo de
/// uma palavra: sem os marcadores "(de X)", "(passado de X)", "(+ 's…)" e
/// "(nome)", cortado na 1ª vírgula/ponto e vírgula/parêntese e com "…" além de
/// [max] letras. "capaz, apto (be able to: conseguir)" → "capaz".
String traducaoCurta(String? gloss, {int max = 18}) {
  if (gloss == null) return '';
  final limpo = gloss
      .replaceAll(_reLema, '')
      .replaceAll(RegExp(r"\(\+ 's[^()]*\)"), '')
      .replaceAll(_reNomeProprio, '')
      .trim();
  var s = limpo.split(RegExp('[,;(]')).first.trim();
  if (s.isEmpty) s = limpo.replaceAll(RegExp(r'\([^()]*\)'), '').split(RegExp('[,;]')).first.trim();
  if (s.isEmpty) s = gloss.replaceAll(RegExp('[()]'), '').split(RegExp('[,;]')).first.trim();
  if (s.length > max && max > 1) s = '${s.substring(0, max - 1).trimRight()}…';
  return s;
}

/// A base que o próprio verbete declara: "aceitou (de accept)" → accept,
/// "foi (passado de go)" → go, "contas (plural de account)" → account. Null sem marcador.
String? baseDoLema(String? gloss) => gloss == null ? null : _reLema.firstMatch(gloss)?.group(1);

/// O verbete é de um nome próprio ("Mike (nome)", "Chicago (cidade)"… e os que começam com maiúscula e
/// explicam o nome entre parênteses: "Texas (estado dos EUA)", "San (São, em nomes de lugares)")?
bool ehNomeProprio(String? gloss) =>
    gloss != null &&
    (_reNomeProprio.hasMatch(gloss) ||
        (gloss.isNotEmpty && gloss[0] != gloss[0].toLowerCase() && _reNomeExplicado.hasMatch(gloss)));

final _reNomeExplicado =
    RegExp(r'\([^()]*\b(nome|nomes|cidade|país|estado|sobrenome|continente|inventor|inventora)\b');

/// Uma palavra que a lição apresenta (ou que a pessoa vai treinar).
class PalavraNova extends Equatable {
  /// Como se escreve: minúsculas, salvo o que em inglês sempre tem maiúscula (Monday, English).
  final String en;

  /// Tradução curta ([traducaoCurta]) e o verbete inteiro do dicionário.
  final String pt;
  final String ptCompleta;

  /// Lição onde a palavra apareceu (vazio = não veio de lição).
  final String licaoId;

  /// Uma frase do curso com a palavra, a tradução dela e o id da frase.
  final String exemplo;
  final String exemploPt;
  final String trechoId;

  const PalavraNova({
    required this.en,
    required this.pt,
    this.ptCompleta = '',
    this.licaoId = '',
    this.exemplo = '',
    this.exemploPt = '',
    this.trechoId = '',
  });

  /// A chave da palavra (no banco, nos mapas): minúsculas.
  String get chave => en.toLowerCase();

  /// Só letras A–Z, 3 a 14: entra nos jogos do Arcade (que comparam letra a letra).
  bool get deJogo => _reDeJogo.hasMatch(en);

  @override
  List<Object?> get props => [en, pt, ptCompleta, licaoId, exemplo, exemploPt, trechoId];
}

/// O que se sabe de uma palavra do curso: a 1ª aparição e o verbete.
class _Info {
  final String gloss;
  final String licaoId;
  final String exemplo, exemploPt, trechoId;
  _Info(this.gloss, this.licaoId, this.exemplo, this.exemploPt, this.trechoId);
}

/// O índice das palavras do curso: as novas de cada lição, o pool digitável de
/// cada lição, onde cada palavra aparece primeiro e a tradução curta dela.
/// Construído uma vez ([IndicePalavras.de] memoriza pelo par trilhas/dicionário).
class IndicePalavras {
  /// Id da lição → palavras novas dela (palavras do alvo primeiro, no máximo [maxPorLicao]).
  final Map<String, List<PalavraNova>> novasPorLicao;

  /// Id da lição → palavras digitáveis dela (só letras, 3–14, sem nomes próprios; inclui as de função).
  final Map<String, List<String>> poolPorLicao;

  /// Palavra (minúsculas) → id da lição em que aparece pela 1ª vez.
  final Map<String, String> primeiraLicao;

  /// Os nomes das personagens (mike, ana…): nunca são palavra de treino.
  final Set<String> nomes;

  /// O dicionário com que o índice foi feito.
  final Dicionario dic;

  final Map<String, _Info> _info;
  final Map<String, String> _formas;

  /// As trilhas do curso (sem as próprias) com que o índice foi feito — a chave do memo.
  final List<Trilha> _trilhas;

  static const maxPorLicao = 8;
  static const maxPorTrilha = 12;

  IndicePalavras._(this.novasPorLicao, this.poolPorLicao, this.primeiraLicao, this.nomes, this.dic, this._info,
      this._formas, this._trilhas);

  static IndicePalavras? _memo;

  /// O índice de [trilhas] (as próprias — textos colados — ficam de fora). Chamar de novo com as
  /// MESMAS trilhas do curso (mesmas instâncias, mesma ordem) devolve o mesmo índice, sem refazer —
  /// mesmo que a lista seja nova ou as próprias tenham mudado (colar/apagar um texto não refaz o índice).
  static IndicePalavras de(List<Trilha> trilhas, Dicionario dic) {
    final m = _memo;
    if (m != null && identical(m.dic, dic) && _mesmasDoCurso(m._trilhas, trilhas)) return m;
    return _memo = _construir(trilhas, dic);
  }

  /// [curso] (as do curso, guardadas no índice) são as mesmas instâncias, na mesma ordem, que as não
  /// próprias de [trilhas]?
  static bool _mesmasDoCurso(List<Trilha> curso, List<Trilha> trilhas) {
    var i = 0;
    for (final t in trilhas) {
      if (t.propria) continue;
      if (i >= curso.length || !identical(curso[i], t)) return false;
      i++;
    }
    return i == curso.length;
  }

  /// [en] é palavra de função (the, and, with…) ou nome de personagem? Essas nunca viram cartão nem
  /// entrada nova no banco vinda dos jogos.
  bool ehFuncaoOuNome(String en) {
    final k = Dicionario.normalizar(en);
    return stopwordsEn.contains(k) || nomes.contains(k);
  }

  /// A tradução curta de [en] (qualquer palavra do curso), ou null.
  String? traducao(String en) {
    final i = _info[Dicionario.normalizar(en)];
    if (i == null) return null;
    final t = traducaoCurta(i.gloss);
    return t.isEmpty ? null : t;
  }

  /// O verbete inteiro de [en], ou null.
  String? traducaoCompleta(String en) => _info[Dicionario.normalizar(en)]?.gloss;

  /// A 1ª frase do curso com [en] e a tradução dela, ou null.
  ({String frase, String traducao, String trechoId})? exemploDe(String en) {
    final i = _info[Dicionario.normalizar(en)];
    return i == null ? null : (frase: i.exemplo, traducao: i.exemploPt, trechoId: i.trechoId);
  }

  /// Como [en] se escreve no curso (Monday, English; o resto em minúsculas).
  String formaDe(String en) {
    final k = Dicionario.normalizar(en);
    return _formas[k] ?? k;
  }

  /// A palavra do curso como [PalavraNova] (null fora do curso / sem verbete).
  PalavraNova? palavra(String en) {
    final k = Dicionario.normalizar(en);
    final i = _info[k];
    if (i == null) return null;
    return PalavraNova(
      en: _formas[k] ?? k,
      pt: traducaoCurta(i.gloss),
      ptCompleta: i.gloss,
      licaoId: i.licaoId,
      exemplo: i.exemplo,
      exemploPt: i.exemploPt,
      trechoId: i.trechoId,
    );
  }

  /// As palavras novas da lição [licaoId] (vazio se não houver/for desconhecida).
  List<PalavraNova> novasDe(String licaoId) => novasPorLicao[licaoId] ?? const [];

  /// As palavras que os jogos do Arcade usam quando a pessoa ESCOLHE a lição [l] (as "lições das palavras
  /// dos jogos"): (como se escreve, tradução curta). Primeiro as novas dela (as do alvo antes); depois as
  /// outras palavras de conteúdo das frases da lição que o dicionário traduz — com os filtros das novas
  /// (sem palavras de função, nomes, números, apóstrofo nem menos de 3 letras), então lição com 0–2
  /// novas também contribui. Nos cartões de UMA palavra (Meus cartões, textos colados), o alvo entra com
  /// a tradução do cartão mesmo fora do dicionário. Só letras, 3–14. Vale também para as lições próprias;
  /// memorizado por instância de lição.
  List<(String, String)> palavrasDeJogo(Licao l) => _jogoPorLicao[l] ??= List.unmodifiable(_palavrasDeJogo(l));

  final _jogoPorLicao = Expando<List<(String, String)>>('palavrasDeJogo');

  /// As palavras de FUNÇÃO da lição [l] que dá pra digitar (how, you, about, with…: só letras, 3–14, com
  /// tradução no dicionário, sem nomes) — as que [palavrasDeJogo] deixa de fora. Com a lição escolhida
  /// para os jogos elas entram depois das de conteúdo: uma lição de diálogo curto do A1 tem só 6–12
  /// palavras de conteúdo, e sem estas o jogo enchia de palavras de fora.
  List<(String, String)> comunsDeJogo(Licao l) => _comunsPorLicao[l] ??= List.unmodifiable(_comunsDeJogo(l));

  final _comunsPorLicao = Expando<List<(String, String)>>('comunsDeJogo');

  List<(String, String)> _comunsDeJogo(Licao l) {
    final r = <(String, String)>[];
    final vistas = {for (final (w, _) in palavrasDeJogo(l)) w.toLowerCase()};
    for (final tr in l.trechos) {
      for (final m in _reToken.allMatches(tr.cod)) {
        final k = Dicionario.normalizar(m.group(0)!);
        if (!stopwordsEn.contains(k) || !_reDeJogo.hasMatch(k) || nomes.contains(k)) continue;
        if (vistas.contains(k)) continue;
        final pt = traducaoCurta(dic.literal(k));
        if (pt.isEmpty) continue;
        vistas.add(k);
        r.add((k, pt));
      }
    }
    return r;
  }

  List<(String, String)> _palavrasDeJogo(Licao l) {
    final r = <(String, String)>[];
    final vistas = <String>{};
    void por(String forma, String pt) {
      if (pt.isEmpty || !_reDeJogo.hasMatch(forma)) return;
      if (vistas.add(forma.toLowerCase())) r.add((forma, pt));
    }

    for (final p in novasDe(l.id)) {
      por(p.en, p.pt);
    }
    for (final tr in l.trechos) {
      for (final m in _reToken.allMatches(tr.cod)) {
        final k = Dicionario.normalizar(m.group(0)!);
        if (k.isEmpty || vistas.contains(k)) continue;
        final gloss = dic.literal(k);
        if (!_treinavel(k, gloss, nomes)) continue;
        por(_formas[k] ?? k, traducaoCurta(gloss));
      }
      // cartão de uma palavra só: o alvo (ou o próprio trecho) com a tradução do cartão
      final alvo = (tr.alvo.isNotEmpty ? tr.alvo : tr.cod).trim().replaceAll(_rePontas, '');
      final pt = (tr.alvo.isNotEmpty ? tr.alvoPt : tr.dicaPlana).trim();
      final k = alvo.toLowerCase();
      if (pt.isNotEmpty &&
          _reDeJogo.hasMatch(alvo) &&
          !vistas.contains(k) &&
          !stopwordsEn.contains(k) &&
          !nomes.contains(k) &&
          !ehNomeProprio(dic.literal(k))) {
        por(_formas[k] ?? alvo, traducaoCurta(pt));
      }
    }
    return r;
  }

  /// Todas as palavras das frases da lição [l] que dá para estudar sozinhas (o "🎯 Escolher palavras"):
  /// as novas dela primeiro e depois as outras na ordem em que aparecem, inclusive as de função e as
  /// curtas (you, there, me). Cada uma vem com uma frase da PRÓPRIA lição como exemplo (as novas, com a
  /// delas). Ficam de fora os nomes das personagens, os nomes próprios, os números e o que o dicionário
  /// não traduz. Memorizado por instância de lição.
  List<PalavraNova> palavrasParaEstudar(Licao l) =>
      _estudarPorLicao[l] ??= List.unmodifiable(_palavrasParaEstudar(l));

  final _estudarPorLicao = Expando<List<PalavraNova>>('palavrasParaEstudar');

  List<PalavraNova> _palavrasParaEstudar(Licao l) {
    final r = <PalavraNova>[...novasDe(l.id)];
    final vistas = {for (final p in r) p.chave};
    for (final tr in l.trechos) {
      for (final m in _reToken.allMatches(tr.cod)) {
        final k = Dicionario.normalizar(m.group(0)!);
        if (k.isEmpty || vistas.contains(k)) continue;
        if (nomes.contains(k) || _reDigito.hasMatch(k) || _reSoletrada.hasMatch(k)) continue;
        final gloss = dic.literal(k);
        if (gloss == null || ehNomeProprio(gloss)) continue;
        final pt = traducaoCurta(gloss);
        if (pt.isEmpty) continue;
        vistas.add(k);
        r.add(PalavraNova(
          en: _formas[k] ?? k,
          pt: pt,
          ptCompleta: gloss,
          licaoId: l.id,
          exemplo: tr.cod,
          exemploPt: tr.dicaPlana,
          trechoId: tr.id,
        ));
      }
    }
    return r;
  }

  /// As palavras novas da trilha [t]: as das lições dela, sem repetir, revezando entre as lições
  /// (cada lição contribui), no máximo [max]. Trilha própria = vazio.
  List<PalavraNova> novasDaTrilha(Trilha t, {int max = maxPorTrilha}) {
    if (t.propria) return const [];
    final listas = [for (final l in t.licoes) novasDe(l.id)];
    final r = <PalavraNova>[];
    final vistas = <String>{};
    for (var i = 0; r.length < max; i++) {
      var algum = false;
      for (final ls in listas) {
        if (i >= ls.length) continue;
        algum = true;
        if (vistas.add(ls[i].chave)) r.add(ls[i]);
        if (r.length >= max) break;
      }
      if (!algum) break;
    }
    return r;
  }

  // ---------- construção ----------

  static bool _inicioDeFrase(String cod, int inicio) {
    var antes = cod.substring(0, inicio).trimRight();
    antes = antes.replaceAll(RegExp('["\'(\\[“‘]+\$'), '').trimRight();
    return antes.isEmpty || RegExp(r'[.!?:]$').hasMatch(antes);
  }

  static String _semAcento(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = de.indexOf(ch);
      b.write(i >= 0 ? para[i] : ch);
    }
    return b.toString();
  }

  /// O sentido principal de duas palavras "bate" (trabalha × trabalho)? Usado para aceitar uma base
  /// adivinhada pelas regras de flexão ("thing" NÃO vem de "the", "evening" NÃO vem de "even").
  static bool _mesmoSentido(String? a, String? b) {
    if (a == null || b == null) return false;
    List<String> raizes(String g) => [
          for (final p in _semAcento(traducaoCurta(g, max: 60)).split(RegExp(r'[^a-z]+')))
            if (p.length >= 3) p.substring(0, 3),
        ];
    final ra = raizes(a).toSet();
    return raizes(b).any(ra.contains);
  }

  /// As bases de [w] que contam para "já foi apresentada": a do próprio verbete e as das regras de
  /// flexão que existem no dicionário e têm o mesmo sentido.
  static List<String> _basesValidas(String w, String gloss, Dicionario dic) {
    final r = <String>[];
    final b = baseDoLema(gloss);
    if (b != null && b != w) r.add(b);
    for (final c in Dicionario.bases(w)) {
      if (c == w || r.contains(c)) continue;
      final gc = dic.entradas[c];
      if (gc != null && _mesmoSentido(gloss, gc)) r.add(c);
    }
    return r;
  }

  /// Passa nos filtros de "palavra que se treina" (sem olhar se é a 1ª vez)?
  static bool _treinavel(String k, String? gloss, Set<String> nomes) =>
      gloss != null &&
      k.length >= 3 &&
      !stopwordsEn.contains(k) &&
      !k.contains("'") &&
      !_reDigito.hasMatch(k) &&
      !_reSoletrada.hasMatch(k) &&
      !ehNomeProprio(gloss) &&
      !nomes.contains(k);

  static Set<String> _palavrasDoAlvo(Licao l) => {
        for (final t in l.trechos)
          if (t.alvo.isNotEmpty)
            for (final m in _reToken.allMatches(t.alvo)) Dicionario.normalizar(m.group(0)!),
      };

  static IndicePalavras _construir(List<Trilha> trilhas, Dicionario dic) {
    final curso = [for (final t in trilhas) if (!t.propria) t];

    // 1ª passada: os nomes das personagens e como cada palavra se escreve no MEIO da frase
    final quem = <String>{};
    final meio = <String, int>{}, meioMaiuscula = <String, int>{};
    final formaMaiuscula = <String, String>{};
    for (final t in curso) {
      for (final l in t.licoes) {
        for (final tr in l.trechos) {
          if (tr.quem.isNotEmpty && tr.quem != 'voce') quem.addAll(tr.quem.split('-'));
          for (final m in _reToken.allMatches(tr.cod)) {
            if (_inicioDeFrase(tr.cod, m.start)) continue;
            final w = m.group(0)!;
            final k = Dicionario.normalizar(w);
            meio[k] = (meio[k] ?? 0) + 1;
            if (w[0] != w[0].toLowerCase()) {
              meioMaiuscula[k] = (meioMaiuscula[k] ?? 0) + 1;
              formaMaiuscula[k] = w;
            }
          }
        }
      }
    }
    // personagem só é "nome" se o dicionário não a conhece como palavra comum (stakeholder é palavra)
    final nomes = {
      for (final q in quem)
        if (dic.entradas[q] == null || ehNomeProprio(dic.entradas[q])) q,
    };
    final formas = <String, String>{};
    for (final e in meio.entries) {
      if (meioMaiuscula[e.key] == e.value && !ehNomeProprio(dic.entradas[e.key])) {
        formas[e.key] = formaMaiuscula[e.key]!;
      }
    }

    // 2ª passada: em ordem de curso, lição por lição
    final info = <String, _Info>{};
    final primeira = <String, String>{};
    final apresentadas = <String>{}; // tudo que já apareceu + as bases declaradas
    final novasPor = <String, List<PalavraNova>>{};
    final poolPor = <String, List<String>>{};
    for (final t in curso) {
      for (final l in t.licoes) {
        if (l.id.isEmpty) continue;
        final doAlvo = _palavrasDoAlvo(l);
        final novas = <PalavraNova>[];
        final pool = <String>[];
        final noPool = <String>{};
        for (final tr in l.trechos) {
          for (final m in _reToken.allMatches(tr.cod)) {
            final k = Dicionario.normalizar(m.group(0)!);
            if (k.isEmpty) continue;
            final gloss = dic.literal(k);
            final primeiraVez = !primeira.containsKey(k);
            if (primeiraVez) {
              primeira[k] = l.id;
              if (gloss != null) info[k] = _Info(gloss, l.id, tr.cod, tr.dicaPlana, tr.id);
            }
            final forma = formas[k] ?? k;
            // pool dos jogos: tudo que é digitável e tem tradução (palavras de função inclusive)
            if (gloss != null && !ehNomeProprio(gloss) && !nomes.contains(k) && _reDeJogo.hasMatch(forma) &&
                noPool.add(k)) {
              pool.add(forma);
            }
            final jaApresentada = apresentadas.contains(k);
            apresentadas.add(k);
            if (!primeiraVez || jaApresentada || !_treinavel(k, gloss, nomes)) continue;
            final bases = _basesValidas(k, gloss!, dic);
            final daBase = bases.any(apresentadas.contains);
            final declarada = baseDoLema(gloss);
            if (declarada != null) apresentadas.add(declarada);
            if (daBase) continue;
            novas.add(PalavraNova(
              en: forma,
              pt: traducaoCurta(gloss),
              ptCompleta: gloss,
              licaoId: l.id,
              exemplo: tr.cod,
              exemploPt: tr.dicaPlana,
              trechoId: tr.id,
            ));
          }
        }
        // as do alvo (o que a lição ensina) primeiro; a ordem de aparição no resto
        final ordenadas = [
          ...novas.where((p) => doAlvo.contains(p.chave)),
          ...novas.where((p) => !doAlvo.contains(p.chave)),
        ];
        novasPor[l.id] = List.unmodifiable(ordenadas.take(maxPorLicao));
        poolPor[l.id] = List.unmodifiable(pool);
      }
    }
    return IndicePalavras._(novasPor, poolPor, primeira, nomes, dic, info, formas, List.unmodifiable(curso));
  }
}

/// As palavras novas de uma lição de TEXTO PRÓPRIO (colado pela pessoa): as que o curso ainda não
/// apresentou a ela — a 1ª lição da palavra não existe no curso ou ainda não foi concluída — com os
/// mesmos filtros e o mesmo teto das lições do curso.
List<PalavraNova> novasDaLicaoPropria(Licao licao, IndicePalavras indice,
    {Set<String> concluidas = const {}, int max = IndicePalavras.maxPorLicao}) {
  final dic = indice.dic;
  bool sabida(String k) {
    final l = indice.primeiraLicao[k];
    return l != null && concluidas.contains(l);
  }

  final doAlvo = IndicePalavras._palavrasDoAlvo(licao);
  final vistas = <String>{};
  final novas = <PalavraNova>[];
  for (final tr in licao.trechos) {
    for (final m in _reToken.allMatches(tr.cod)) {
      final k = Dicionario.normalizar(m.group(0)!);
      if (k.isEmpty || !vistas.add(k)) continue;
      final gloss = dic.literal(k);
      if (!IndicePalavras._treinavel(k, gloss, indice.nomes) || sabida(k)) continue;
      if (IndicePalavras._basesValidas(k, gloss!, dic).any((b) => sabida(b) || vistas.contains(b))) continue;
      novas.add(PalavraNova(
        en: indice._formas[k] ?? k,
        pt: traducaoCurta(gloss),
        ptCompleta: gloss,
        licaoId: licao.id,
        exemplo: tr.cod,
        exemploPt: tr.dicaPlana,
        trechoId: tr.id,
      ));
    }
  }
  return [
    ...novas.where((p) => doAlvo.contains(p.chave)),
    ...novas.where((p) => !doAlvo.contains(p.chave)),
  ].take(max).toList();
}
