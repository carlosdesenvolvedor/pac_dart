import '../../curso/domain/curriculo.dart';
import 'baralhos.dart';
import 'setlist.dart';

/// Uma frase da fila do "🎧 Ouvir", já resolvida.
class Faixa {
  /// `chaveDaFrase`; [pt] = `dicaPlana`.
  final String chave, en, pt, quem;

  /// '' numa frase órfã (saiu do curso; toca o retrato).
  final String licaoId, licaoNome, licaoEmoji, trilhaNome, etapa;

  /// Qual item da setlist gerou a faixa.
  final int itemIdx;
  final bool primeiraDaLicao, temGravacao;

  /// Duração a 1×.
  final double segundos;

  const Faixa({
    required this.chave,
    required this.en,
    this.pt = '',
    this.quem = '',
    this.licaoId = '',
    this.licaoNome = '',
    this.licaoEmoji = '',
    this.trilhaNome = '',
    this.etapa = '',
    this.itemIdx = 0,
    this.primeiraDaLicao = false,
    this.temGravacao = false,
    this.segundos = 0,
  });
}

/// Onde cada frase/lição/unidade mora nas trilhas (para resolver as refs dos itens).
class IndiceOuvir {
  final List<Trilha> trilhas;

  final Map<String, ({int t, int l, int f})> _frases = {};
  final Map<String, ({int t, int l})> _licoes = {};
  final Map<String, int> _trilhas = {};
  final List<String> _etapas = [];

  IndiceOuvir._(this.trilhas) {
    final etapasVistas = <String>{};
    for (var t = 0; t < trilhas.length; t++) {
      final tr = trilhas[t];
      _trilhas.putIfAbsent(tr.baralhoId, () => t);
      if (!tr.propria && tr.etapa.isNotEmpty && etapasVistas.add(tr.etapa)) _etapas.add(tr.etapa);
      for (var l = 0; l < tr.licoes.length; l++) {
        final li = tr.licoes[l];
        if (li.id.isNotEmpty) _licoes.putIfAbsent(li.id, () => (t: t, l: l));
        for (var f = 0; f < li.trechos.length; f++) {
          // a 1ª ocorrência vale: o curso vem antes dos textos do aluno
          _frases.putIfAbsent(chaveDaFrase(li.trechos[f]), () => (t: t, l: l, f: f));
        }
      }
    }
  }

  static IndiceOuvir? _ultimo;

  /// Memoizado por `identical(trilhas)`.
  factory IndiceOuvir.de(List<Trilha> trilhas) {
    final u = _ultimo;
    if (u != null && identical(u.trilhas, trilhas)) return u;
    return _ultimo = IndiceOuvir._(trilhas);
  }

  ({int t, int l, int f})? frase(String chave) => _frases[chave];

  ({int t, int l})? licao(String id) => _licoes[id];

  int? trilha(String baralhoId) => _trilhas[baralhoId];

  /// Os rótulos completos, na ordem do curso (sem os textos do aluno).
  List<String> get etapas => List.unmodifiable(_etapas);

  /// O índice da frase [chave] dentro da lição [l] da trilha [t]; null se ela não está lá.
  int? _fraseNaLicao(int t, int l, String chave) {
    final trechos = trilhas[t].licoes[l].trechos;
    for (var f = 0; f < trechos.length; f++) {
      if (chaveDaFrase(trechos[f]) == chave) return f;
    }
    return null;
  }

  /// As trilhas do curso (sem as próprias) que um item `etapa`/`curso` pega, na ordem.
  Iterable<int> _trilhasDo(ItemSetlist item) sync* {
    for (var t = 0; t < trilhas.length; t++) {
      final tr = trilhas[t];
      if (tr.propria) continue;
      if (item.tipo == TipoItem.etapa && ItemSetlist.codigoEtapa(tr.etapa) != item.ref) continue;
      yield t;
    }
  }
}

/// A fila pronta para tocar.
class FilaOuvir {
  final List<Faixa> faixas;

  /// Onde cada item começa em [faixas] (um item que não resolveu aponta para onde o próximo começa).
  final List<int> inicioDoItem;

  /// Ids dos itens que não resolveram.
  final List<String> indisponiveis;

  const FilaOuvir({this.faixas = const [], this.inicioDoItem = const [], this.indisponiveis = const []});

  // somas de prefixos, calculadas uma vez por fila (a classe é const, então ficam fora dela)
  static final _somas = Expando<List<double>>();

  List<double> get _prefixos {
    final pronto = _somas[this];
    if (pronto != null) return pronto;
    final p = List<double>.filled(faixas.length + 1, 0);
    for (var i = 0; i < faixas.length; i++) {
      p[i + 1] = p[i] + faixas[i].segundos;
    }
    return _somas[this] = p;
  }

  double get segundosTotal => _prefixos.last;

  /// Soma de prefixos: os segundos de [desde] até o fim.
  double segundosDe(int desde) {
    final p = _prefixos;
    return p.last - p[desde.clamp(0, faixas.length)];
  }

  /// Tenta [dica] primeiro, depois procura (a ocorrência mais perto da dica); 0 se não achar.
  int indiceDaChave(String chave, {int dica = 0}) {
    final n = faixas.length;
    if (n == 0) return 0;
    final d = dica.clamp(0, n - 1);
    if (faixas[d].chave == chave) return d;
    for (var passo = 1; passo < n; passo++) {
      final antes = d - passo, depois = d + passo;
      if (depois < n && faixas[depois].chave == chave) return depois;
      if (antes >= 0 && faixas[antes].chave == chave) return antes;
      if (antes < 0 && depois >= n) break;
    }
    return 0;
  }

  /// O começo da lição da faixa [i] (a faixa com `primeiraDaLicao` em [i] ou antes; 0 no limite).
  int inicioDaLicao(int i) {
    if (faixas.isEmpty) return 0;
    var j = i.clamp(0, faixas.length - 1);
    while (j > 0 && !faixas[j].primeiraDaLicao) {
      j--;
    }
    return j;
  }

  /// O começo da próxima lição depois de [i]; `faixas.length` (o fim da fila) se não há outra.
  int proximaLicao(int i) {
    for (var j = (i < 0 ? 0 : i + 1); j < faixas.length; j++) {
      if (faixas[j].primeiraDaLicao) return j;
    }
    return faixas.length;
  }

  /// O começo da lição ANTERIOR à da faixa [i]; 0 se [i] já está na primeira.
  int licaoAnterior(int i) {
    final inicio = inicioDaLicao(i);
    return inicio == 0 ? 0 : inicioDaLicao(inicio - 1);
  }
}

/// Monta a fila de [itens], na ordem, contra as trilhas de [ix] (ver a tabela de refs do plano):
/// - `frase`: procura em `licaoId`, depois no curso todo; não achou → o retrato EN/PT (órfã, sem lição);
///   nem retrato → indisponível;
/// - `trecho`: as frases de `chaves` na ordem da lição (as que sumiram ficam de fora); nenhuma → a lição;
/// - `licao` / `trilha` / `etapa` / `curso`: todas as frases, na ordem (etapa e curso sem os textos do aluno).
///
/// Frases sem texto são puladas. `primeiraDaLicao` marca o começo de cada lição na fila (a primeira faixa,
/// a troca de lição, ou um item novo que recomeça a lição do começo; cada órfã é a sua "lição").
FilaOuvir resolverFila(
  IndiceOuvir ix,
  List<ItemSetlist> itens, {
  required double Function(String en) duracaoDe,
  required bool Function(String en) temGravacao,
}) {
  final faixas = <Faixa>[];
  final inicio = <int>[];
  final indisponiveis = <String>[];
  var grupoAnterior = '';

  void por(int k, int t, int l, int f) {
    final tr = ix.trilhas[t];
    final li = tr.licoes[l];
    final fr = li.trechos[f];
    if (fr.cod.trim().isEmpty) return;
    final grupo = li.id.isEmpty ? 't$t.l$l' : li.id;
    final primeira = faixas.isEmpty ||
        grupo != grupoAnterior ||
        (faixas.last.itemIdx != k && f == 0);
    grupoAnterior = grupo;
    faixas.add(Faixa(
      chave: chaveDaFrase(fr),
      en: fr.cod,
      pt: fr.dicaPlana,
      quem: fr.quem,
      licaoId: li.id,
      licaoNome: li.nome,
      licaoEmoji: li.emoji,
      trilhaNome: tr.nivel,
      etapa: tr.etapa,
      itemIdx: k,
      primeiraDaLicao: primeira,
      temGravacao: temGravacao(fr.cod),
      segundos: duracaoDe(fr.cod),
    ));
  }

  void porLicao(int k, int t, int l) {
    final n = ix.trilhas[t].licoes[l].trechos.length;
    for (var f = 0; f < n; f++) {
      por(k, t, l, f);
    }
  }

  void porTrilha(int k, int t) {
    final n = ix.trilhas[t].licoes.length;
    for (var l = 0; l < n; l++) {
      porLicao(k, t, l);
    }
  }

  for (var k = 0; k < itens.length; k++) {
    final item = itens[k];
    final antes = faixas.length;
    inicio.add(antes);
    switch (item.tipo) {
      case TipoItem.frase:
        final onde = _ondeDaFrase(ix, item);
        if (onde != null) {
          por(k, onde.t, onde.l, onde.f);
        } else if (item.en.trim().isNotEmpty) {
          grupoAnterior = 'orfa:$k';
          faixas.add(Faixa(
            chave: item.ref,
            en: item.en,
            pt: item.pt,
            itemIdx: k,
            primeiraDaLicao: true,
            temGravacao: temGravacao(item.en),
            segundos: duracaoDe(item.en),
          ));
        }
      case TipoItem.trecho:
        final li = ix.licao(item.ref) ?? ix.licao(item.licaoId);
        if (li != null) {
          for (final f in _trechoNaLicao(ix, li, item)) {
            por(k, li.t, li.l, f);
          }
        }
      case TipoItem.licao:
        final li = ix.licao(item.ref);
        if (li != null) porLicao(k, li.t, li.l);
      case TipoItem.trilha:
        final t = ix.trilha(item.ref);
        if (t != null) porTrilha(k, t);
      case TipoItem.etapa:
      case TipoItem.curso:
        for (final t in ix._trilhasDo(item)) {
          porTrilha(k, t);
        }
    }
    if (faixas.length == antes) indisponiveis.add(item.id);
  }
  return FilaOuvir(faixas: faixas, inicioDoItem: inicio, indisponiveis: indisponiveis);
}

/// Onde está a frase de um item `frase`: na lição dica primeiro, depois no índice global.
({int t, int l, int f})? _ondeDaFrase(IndiceOuvir ix, ItemSetlist item) {
  if (item.licaoId.isNotEmpty) {
    final li = ix.licao(item.licaoId);
    if (li != null) {
      final f = ix._fraseNaLicao(li.t, li.l, item.ref);
      if (f != null) return (t: li.t, l: li.l, f: f);
    }
  }
  return ix.frase(item.ref);
}

/// Os índices das frases de um `trecho` na lição [li] (na ordem da lição); nenhuma achada → todas.
List<int> _trechoNaLicao(IndiceOuvir ix, ({int t, int l}) li, ItemSetlist item) {
  final trechos = ix.trilhas[li.t].licoes[li.l].trechos;
  final querer = item.chaves.toSet();
  final achadas = [
    for (var f = 0; f < trechos.length; f++)
      if (querer.contains(chaveDaFrase(trechos[f]))) f,
  ];
  return achadas.isEmpty ? [for (var f = 0; f < trechos.length; f++) f] : achadas;
}

/// Quantas frases [item] toca (a mesma conta de [resolverFila], sem montar a fila).
int contarFrases(IndiceOuvir ix, ItemSetlist item) {
  int naLicao(int t, int l) => ix.trilhas[t].licoes[l].trechos.where((f) => f.cod.trim().isNotEmpty).length;
  int naTrilha(int t) {
    var n = 0;
    for (var l = 0; l < ix.trilhas[t].licoes.length; l++) {
      n += naLicao(t, l);
    }
    return n;
  }

  switch (item.tipo) {
    case TipoItem.frase:
      final onde = _ondeDaFrase(ix, item);
      if (onde != null) return ix.trilhas[onde.t].licoes[onde.l].trechos[onde.f].cod.trim().isEmpty ? 0 : 1;
      return item.en.trim().isEmpty ? 0 : 1;
    case TipoItem.trecho:
      final li = ix.licao(item.ref) ?? ix.licao(item.licaoId);
      if (li == null) return 0;
      final trechos = ix.trilhas[li.t].licoes[li.l].trechos;
      return _trechoNaLicao(ix, li, item).where((f) => trechos[f].cod.trim().isNotEmpty).length;
    case TipoItem.licao:
      final li = ix.licao(item.ref);
      return li == null ? 0 : naLicao(li.t, li.l);
    case TipoItem.trilha:
      final t = ix.trilha(item.ref);
      return t == null ? 0 : naTrilha(t);
    case TipoItem.etapa:
    case TipoItem.curso:
      var n = 0;
      for (final t in ix._trilhasDo(item)) {
        n += naTrilha(t);
      }
      return n;
  }
}

/// "38 s", "4 min", "3 h 58 min" (arredondado ao minuto a partir de 1 min; "3 h" quando fecha a hora).
String formatarDuracao(double seg) {
  if (!seg.isFinite || seg <= 0) return '0 s';
  if (seg < 59.5) return '${seg.round()} s';
  final minutos = (seg / 60).round();
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60, m = minutos % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
