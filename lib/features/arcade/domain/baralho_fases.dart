// O baralho por FASE dos jogos de digitação do inglês (Rali, Chuva e Turismo): cada fase traz palavras
// NOVAS (o vocabulário inteiro roda antes de alguma voltar), traz MAIS palavras que a anterior, e põe de
// propósito algumas pra revisar 🔁 — as que a pessoa errou, deixou cair ou demorou mais pra digitar
// nesta partida, e (na 1ª fase) um par das teimosas/fracas do banco. Dart puro: o relógio é injetado e
// a única fonte de sorte é o [Random] dado (mesma semente + mesmas chamadas = mesmos baralhos).

import 'dart:math';

import 'vocabulario_jogo.dart';

/// Por que a carta está no baralho.
enum OrigemCarta {
  /// Palavra que a pessoa ainda não viu nesta partida.
  nova,

  /// Já vista, voltando só porque o vocabulário acabou (a menos recente primeiro).
  deNovo,

  /// Em foco (as que a pessoa pediu pra treinar): na frente até sair uma vez.
  foco,

  /// Errou ou deixou cair na última vez.
  errou,

  /// Saiu limpa, mas bem mais devagar que o normal da pessoa.
  lenta,

  /// Teimosa/fraca do banco, ainda não vista na partida.
  dificil,
}

extension OrigemCartaX on OrigemCarta {
  /// foco, errou, lenta e dificil levam o 🔁.
  bool get revisao => index >= OrigemCarta.foco.index;
}

/// Uma carta do baralho: a palavra e por que ela veio.
class CartaFase {
  final String palavra;
  final OrigemCarta origem;
  const CartaFase(this.palavra, this.origem);

  bool get revisao => origem.revisao;

  @override
  String toString() => '$palavra(${origem.name})';
}

/// O baralho de UMA fase (nunca vazio).
class DeckFase {
  final int fase;
  final List<CartaFase> cartas;

  /// Quantas cartas a pessoa deve mesmo usar (o Rali: palavra perfeita anda 2 casas e a fase fecha antes
  /// do fim do baralho); = cartas.length quando todas saem.
  final int alcance;

  late final List<String> palavras = List.unmodifiable([for (final c in cartas) c.palavra]);
  late final Set<String> _revisao = {for (final c in cartas) if (c.revisao) c.palavra};
  late final int distintas = palavras.toSet().length;
  late final int novas = {for (final c in cartas) if (c.origem == OrigemCarta.nova) c.palavra}.length;

  DeckFase(this.fase, List<CartaFase> cartas, {int? alcance})
      : cartas = List.unmodifiable(cartas),
        alcance = alcance == null ? cartas.length : alcance.clamp(1, max(1, cartas.length)) {
    if (cartas.isEmpty) throw ArgumentError.value(cartas, 'cartas', 'o baralho da fase não pode ser vazio');
  }

  /// Quantas palavras (distintas) vêm pra revisar 🔁.
  int get revisar => _revisao.length;

  bool ehRevisao(String palavra) => _revisao.contains(palavra);

  /// '14 palavras · 9 novas · 5 pra revisar 🔁' (sem revisão: '12 palavras · 12 novas'; sem novas:
  /// '12 palavras · 4 pra revisar 🔁'; sem nenhuma das duas: '12 palavras · todas já vistas'). Com
  /// [alcance] menor que o baralho: 'até 14 palavras · …' (a fase pode fechar antes do fim).
  String resumo() {
    final n = cartas.length;
    final partes = ['${alcance < n ? 'até ' : ''}$n ${n == 1 ? 'palavra' : 'palavras'}'];
    if (novas > 0) partes.add('$novas ${novas == 1 ? 'nova' : 'novas'}');
    if (revisar > 0) partes.add('$revisar pra revisar 🔁');
    if (novas == 0 && revisar == 0) partes.add('todas já vistas');
    return partes.join(' · ');
  }

  @override
  String toString() => 'DeckFase($fase, $cartas)';
}

/// O que os motores (TiroEngine, TurismoEngine) consomem.
abstract interface class FonteDePalavras {
  /// A próxima carta; nunca falha enquanto o pool da fase não for vazio. [evitar]: palavras que não podem
  /// sair agora (já na tela). [outraInicialQue]: não pode começar com a mesma inicial (minúscula) desta.
  CartaFase proxima({Set<String> evitar = const {}, String? outraInicialQue});

  /// Uma carta de FORA do baralho da fase (a 2ª saída do portal do Turismo): não mexe na fila — a não vista
  /// seguinte que não está pra sair, senão a menos recente. Mesmas regras de [proxima].
  CartaFase proximaExtra({Set<String> evitar = const {}, String? outraInicialQue});
}

/// O histórico de uma palavra na partida.
class _Hist {
  int ocorrencias = 0;
  int ultimaSeq = 0;
  int ultimaErros = 0;
  bool ultimaPerdeu = false;
  double? ultimaMs;
  final List<double> amostras = [];
}

/// O baralho da partida inteira: guarda o que aconteceu com cada palavra e monta, fase a fase, o
/// [DeckFase] (com [abrirFase]); os jogos que tiram uma palavra por vez (Chuva, Turismo) usam [proxima].
class BaralhoFases implements FonteDePalavras {
  final Random _rnd;

  /// As difíceis do banco (teimosas, depois fracas), na ordem, sem repetir.
  final List<String> _dificeis;

  /// Chuva/Turismo: a palavra que caiu (ou saiu com 2+ erros) volta na mesma fase, 3–5 palavras depois.
  final bool reenfileirarNaFase;

  BaralhoFases({
    required Random rnd,
    List<String> dificeis = const [],
    this.reenfileirarNaFase = false,
  })  : _rnd = rnd,
        _dificeis = List.unmodifiable(dificeis.toSet());

  // ---- constantes ----

  /// ~35% do baralho pra revisar (no mínimo 1 se houver candidata, no máximo a metade).
  static const fracaoRevisao = 0.35;

  /// No máximo 2 difíceis do banco por baralho.
  static const dificeisPorFase = 2;

  /// Cartas novas entre duas de revisão.
  static const novasEntreRevisoes = 1;

  /// Lenta: > 1,6 × a mediana (ms por letra) da partida; com 8+ amostras.
  static const fatorLenta = 1.6;

  /// Vai pro banco como lenta: > 2 × a mediana em 2+ ocorrências.
  static const fatorMuitoLenta = 2.0;
  static const amostraMinima = 8;
  static const ocorrenciasMuitoLenta = 2;

  /// As amostras ficam entre 20 e 5000 ms por letra (tecla presa, pausa esquecida).
  static const minMsPorLetra = 20.0;
  static const maxMsPorLetra = 5000.0;

  /// A falha que uma palavra lenta (e limpa) manda pro banco.
  static const falhaLenta = 0.2;

  /// Reenfileirar na fase: com 2+ erros (ou caiu), 3–5 tiradas depois, no máximo 2 vezes por fase.
  static const errosParaReenfileirar = 2;
  static const atrasoMin = 3;
  static const atrasoMax = 5;
  static const maxReenfileirarPorFase = 2;

  /// O tamanho da fase do Rali: 12, 14, 16… até 20.
  static int tamanhoRali(int fase) => min(20, 12 + 2 * (max(1, fase) - 1));

  /// Quantas palavras a fase do Rali usa de verdade: palavra perfeita é TURBO e anda 2 casas, então a
  /// pista de [tamanhoRali] fecha com algo entre a metade e o total — ~2/3 (8, 10, 11… 14). A revisão é
  /// contada e espalhada sobre esse trecho, não sobre o fim do baralho que quase ninguém alcança.
  static int alcanceRali(int fase) => (tamanhoRali(fase) * 2 / 3).ceil();

  /// O tamanho do nível da Chuva (= quantas destruir pra subir): 8, 10, 12… até 16.
  static int tamanhoChuva(int nivel) => min(16, 8 + 2 * (max(1, nivel) - 1));

  /// O pool do Rali (curtas + médias, e as longas com [comLongas]).
  static List<String> poolRali(VocabularioJogo v, {required bool comLongas}) =>
      [...v.curtas, ...v.medias, if (comLongas) ...v.longas];

  /// O pool do nível da Chuva (a mesma regra do TiroEngine: 1 = curtas, 2 = + médias, 3+ = todas).
  static List<String> poolChuva(VocabularioJogo v, int nivel) => switch (nivel) {
        <= 1 => v.curtas,
        2 => [...v.curtas, ...v.medias],
        _ => [...v.curtas, ...v.medias, ...v.longas],
      };

  // ---- estado da partida ----

  final Map<String, _Hist> _hist = {};
  final List<double> _todasAmostras = [];
  double? _medianaCache;
  bool _medianaSuja = true;
  int _seq = 0;
  int _pops = 0;

  /// Relógio de uso (sobe a cada tirada e a cada registro): "a menos recente" no estender.
  int _uso = 0;
  final Map<String, int> _usoEm = {};

  /// A ordem em que o vocabulário roda (sorteada uma vez; cresce quando o pool cresce).
  List<String> _rotacao = [];
  final Set<String> _naRotacao = {};

  Set<String> _focoAtivo = const {};
  final Set<String> _focoVisto = {};
  final Set<String> _lentasEnviadas = {};

  // ---- estado da fase ----

  DeckFase? _deck;
  List<String> _pool = const [];
  Set<String> _poolSet = const {};
  List<CartaFase> _fila = [];
  int _cursor = 0;
  final List<(String, int)> _reenf = [];
  final Map<String, int> _reenfNaFase = {};
  final Set<String> _servidasNaFase = {};
  String? _ultimaTirada;

  /// O baralho da fase aberta agora (null antes da 1ª).
  DeckFase? get deck => _deck;

  bool _visto(String w) => (_hist[w]?.ocorrencias ?? 0) > 0;

  /// Abre a fase [fase] com [tamanho] cartas tiradas de [pool] (não vazio). [foco]: as palavras em foco
  /// (vêm primeiro até saírem uma vez). [aceita]: filtro (o modo memória do Rali: só com tradução) —
  /// ignorado se não sobrar nenhuma. [emJogo]: as que ainda estão na tela da fase anterior (a Chuva sobe de
  /// nível com palavras caindo) — já saíram, então não entram como novas nem como revisão desta fase.
  /// [alcance]: quantas cartas a pessoa deve mesmo usar (o Rali: ~2/3 da pista) — a revisão é ~35% DELAS e
  /// vem espalhada por esse trecho (sem isso: 1 nova / 1 revisão na frente).
  DeckFase abrirFase({
    required int fase,
    required List<String> pool,
    required int tamanho,
    Set<String> foco = const {},
    bool Function(String)? aceita,
    Set<String> emJogo = const {},
    int? alcance,
  }) {
    if (tamanho < 1) throw ArgumentError.value(tamanho, 'tamanho', 'precisa ser ≥ 1');
    // 1. pool sem repetir (pela forma exata), na ordem
    final lista = <String>[];
    final vistas = <String>{};
    for (final w in pool) {
      if (vistas.add(w)) lista.add(w);
    }
    if (lista.isEmpty) throw ArgumentError.value(pool, 'pool', 'o pool da fase não pode ser vazio');

    // 2. a rotação (o embaralhar é o 1º uso do rnd: a fase 1 do Rali sai igual ao baralho antigo)
    if (_rotacao.isEmpty) {
      _rotacao = [...lista]..shuffle(_rnd);
      _naRotacao.addAll(_rotacao);
    } else {
      final fora = [for (final w in lista) if (!_naRotacao.contains(w)) w];
      if (fora.isNotEmpty) _crescerRotacao(fora);
    }

    final filtro = aceita == null || !lista.any(aceita) ? null : aceita;
    final noPool = vistas;
    bool ok(String w) => noPool.contains(w) && (filtro == null || filtro(w));
    final ordem = [for (final w in _rotacao) if (ok(w)) w];

    // 3. o bloco do foco
    final focoSet = foco.toSet();
    if (!_mesmoConjunto(focoSet, _focoAtivo)) {
      _focoAtivo = focoSet;
      _focoVisto.clear();
    }
    final blocoFoco = <String>[
      for (final w in ordem)
        if (_focoAtivo.contains(w) && !_focoVisto.contains(w) && !emJogo.contains(w)) w,
    ].take(tamanho).toList();
    // as que estão na tela ficam de fora (quando saírem viram vistas normalmente)
    final noDeck = {...blocoFoco, ...emJogo};

    // 4. as candidatas a revisão
    final candidatas = _candidatas(ordem.where((w) => !noDeck.contains(w)));

    // 5. quantas revisar (sobre as cartas que a pessoa vai mesmo usar)
    final usa = alcance == null ? tamanho : alcance.clamp(1, tamanho);
    final capBase = min(usa ~/ 2, max(1, (usa * fracaoRevisao).round()));
    final cap = max(0, capBase - blocoFoco.length);
    final revisoes = candidatas.take(cap).toList();
    noDeck.addAll(revisoes.map((c) => c.palavra));

    // 6. as novas (e as "de novo")
    final n = tamanho - blocoFoco.length - revisoes.length;
    final novas = <CartaFase>[];
    for (final w in ordem) {
      if (novas.length >= n) break;
      if (!_visto(w) && !noDeck.contains(w)) novas.add(CartaFase(w, OrigemCarta.nova));
    }
    if (novas.length < n) {
      final vistasOrd = [for (final w in ordem) if (_visto(w) && !noDeck.contains(w)) w]
        ..sort((a, b) => _hist[a]!.ultimaSeq.compareTo(_hist[b]!.ultimaSeq));
      for (final w in vistasOrd) {
        if (novas.length >= n) break;
        novas.add(CartaFase(w, OrigemCarta.deNovo));
      }
    }
    if (novas.length < n) {
      // pool pequeno: roda o pool de novo, sem duas iguais seguidas
      var anterior = novas.isNotEmpty
          ? novas.last.palavra
          : (revisoes.isNotEmpty ? revisoes.last.palavra : (blocoFoco.isNotEmpty ? blocoFoco.last : null));
      var i = 0;
      while (novas.length < n) {
        final w = ordem[i % ordem.length];
        i++;
        if (w == anterior && ordem.length > 1) continue;
        novas.add(CartaFase(w, OrigemCarta.deNovo));
        anterior = w;
      }
    }

    // 7. monta: foco, depois 1 nova / 1 revisão / … (as novas que sobram no fim); com [alcance], as
    // revisões espalhadas pelo trecho que a pessoa vai digitar (nunca a 1ª, nunca duas seguidas)
    final cartas = <CartaFase>[for (final w in blocoFoco) CartaFase(w, OrigemCarta.foco)];
    var iN = 0, iR = 0;
    final r = revisoes.length;
    if (usa < tamanho && r > 0) {
      final total = novas.length + r;
      final trecho = min(total, max(2 * r, usa - blocoFoco.length));
      final posicoes = <int>{};
      var anterior = -1;
      for (var i = 1; i <= r; i++) {
        final p = min(total - 1, max(anterior + 2, (i * trecho / (r + 1)).round()));
        posicoes.add(p);
        anterior = p;
      }
      for (var k = 0; k < total; k++) {
        final revisaoAqui = (posicoes.contains(k) && iR < r) || iN >= novas.length;
        cartas.add(revisaoAqui ? revisoes[iR++] : novas[iN++]);
      }
    } else {
      while (iR < r) {
        for (var k = 0; k < novasEntreRevisoes && iN < novas.length; k++) {
          cartas.add(novas[iN++]);
        }
        cartas.add(revisoes[iR++]);
      }
      while (iN < novas.length) {
        cartas.add(novas[iN++]);
      }
    }
    _semVizinhasIguais(cartas);

    // 8. guarda
    _pool = ordem;
    _poolSet = ordem.toSet();
    _fila = [...cartas];
    _cursor = 0;
    _reenf.clear();
    _reenfNaFase.clear();
    _servidasNaFase.clear();
    final d = DeckFase(fase, cartas, alcance: alcance == null ? null : usa);
    _deck = d;
    return d;
  }

  /// As palavras novas do pool entram na rotação sorteadas no meio das que ainda não saíram (as compridas
  /// da fase 3 do Rali aparecem já nessa fase, não só quando as curtas acabarem).
  void _crescerRotacao(List<String> fora) {
    final novas = [...fora]..shuffle(_rnd);
    final vistas = [for (final w in _rotacao) if (_visto(w)) w];
    final resto = [for (final w in _rotacao) if (!_visto(w)) w];
    final mescla = <String>[];
    var a = 0, b = 0;
    while (a < resto.length || b < novas.length) {
      final faltaA = resto.length - a, faltaB = novas.length - b;
      if (faltaB == 0 || (faltaA > 0 && _rnd.nextInt(faltaA + faltaB) < faltaA)) {
        mescla.add(resto[a++]);
      } else {
        mescla.add(novas[b++]);
      }
    }
    _rotacao = [...vistas, ...mescla];
    _naRotacao.addAll(novas);
  }

  static bool _mesmoConjunto(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  /// As candidatas (já ordenadas): caiu, errou (mais erros primeiro), lenta (mais lenta primeiro) e as
  /// difíceis do banco ainda não vistas (no máximo [dificeisPorFase]).
  List<CartaFase> _candidatas(Iterable<String> palavras) {
    final caiu = <String>[], errou = <String>[], lenta = <String>[];
    final m = mediana;
    final set = palavras.toSet();
    for (final w in set) {
      final h = _hist[w];
      if (h == null || h.ocorrencias == 0) continue;
      if (h.ultimaPerdeu) {
        caiu.add(w);
      } else if (h.ultimaErros > 0) {
        errou.add(w);
      } else if (_ehLenta(h, m)) {
        lenta.add(w);
      }
    }
    int desempate(String a, String b) {
      final s = _hist[a]!.ultimaSeq.compareTo(_hist[b]!.ultimaSeq);
      return s != 0 ? s : a.compareTo(b);
    }

    caiu.sort(desempate);
    errou.sort((a, b) {
      final e = _hist[b]!.ultimaErros.compareTo(_hist[a]!.ultimaErros);
      return e != 0 ? e : desempate(a, b);
    });
    lenta.sort((a, b) {
      final r = _hist[b]!.ultimaMs!.compareTo(_hist[a]!.ultimaMs!);
      return r != 0 ? r : desempate(a, b);
    });
    final dificeis = [
      for (final w in _dificeis)
        if (set.contains(w) && !_visto(w)) w,
    ].take(dificeisPorFase);
    return [
      for (final w in caiu) CartaFase(w, OrigemCarta.errou),
      for (final w in errou) CartaFase(w, OrigemCarta.errou),
      for (final w in lenta) CartaFase(w, OrigemCarta.lenta),
      for (final w in dificeis) CartaFase(w, OrigemCarta.dificil),
    ];
  }

  static bool _ehLenta(_Hist h, double? m) =>
      m != null && !h.ultimaPerdeu && h.ultimaErros == 0 && h.ultimaMs != null && h.ultimaMs! > fatorLenta * m;

  /// Desfaz duas cartas iguais seguidas (só acontece com pool pequeno), trocando com uma mais à frente.
  static void _semVizinhasIguais(List<CartaFase> c) {
    bool vale(int i) =>
        (i == 0 || c[i].palavra != c[i - 1].palavra) && (i == c.length - 1 || c[i].palavra != c[i + 1].palavra);
    for (var i = 1; i < c.length; i++) {
      if (c[i].palavra != c[i - 1].palavra) continue;
      for (var j = i + 1; j < c.length; j++) {
        if (c[j].palavra == c[i].palavra) continue;
        final t = c[i];
        c[i] = c[j];
        c[j] = t;
        if (vale(i) && vale(j)) break;
        c[j] = c[i];
        c[i] = t;
      }
    }
  }

  @override
  CartaFase proxima({Set<String> evitar = const {}, String? outraInicialQue}) {
    if (_deck == null || _pool.isEmpty) throw StateError('abra uma fase antes de tirar palavras');
    _pops++;
    final inicial = outraInicialQue == null || outraInicialQue.isEmpty ? null : outraInicialQue[0].toLowerCase();
    for (var nivel = 0; nivel < 3; nivel++) {
      final ev = nivel == 0 ? evitar : const <String>{};
      final ini = nivel <= 1 ? inicial : null;
      bool passa(String w) => !ev.contains(w) && (ini == null || w.isEmpty || w[0].toLowerCase() != ini);
      final c = _tirar(passa);
      if (c != null) return _servir(c);
    }
    final w = _pool.firstWhere((w) => w != _ultimaTirada, orElse: () => _pool.first);
    return _servir(CartaFase(w, _visto(w) ? OrigemCarta.deNovo : OrigemCarta.nova));
  }

  CartaFase? _tirar(bool Function(String) passa) {
    // 2. reenfileiradas cuja vez chegou
    for (var i = 0; i < _reenf.length; i++) {
      final (w, libera) = _reenf[i];
      if (libera <= _pops && passa(w)) {
        _reenf.removeAt(i);
        return CartaFase(w, OrigemCarta.errou);
      }
    }
    // 3. a fila da fase (a pulada continua a próxima da vez)
    for (var k = _cursor; k < _fila.length; k++) {
      if (!passa(_fila[k].palavra)) continue;
      if (k != _cursor) {
        final t = _fila[_cursor];
        _fila[_cursor] = _fila[k];
        _fila[k] = t;
      }
      return _fila[_cursor++];
    }
    // 4. a fila acabou: estende
    return _estender(passa);
  }

  /// Além do baralho: as não vistas (ainda não servidas na fase), depois as menos recentes.
  CartaFase? _estender(bool Function(String) passa) {
    for (final w in _pool) {
      if (!_visto(w) && !_servidasNaFase.contains(w) && w != _ultimaTirada && passa(w)) {
        return CartaFase(w, OrigemCarta.nova);
      }
    }
    // sem sentinela gigante: no dart2js `1 << 62` dá 0 e nenhuma já usada venceria (a web repetia 2 palavras)
    String? melhor;
    int? melhorUso;
    for (final w in _pool) {
      if (w == _ultimaTirada && _pool.length > 1) continue;
      if (!passa(w)) continue;
      final u = _usoEm[w] ?? -1;
      if (melhorUso == null || u < melhorUso) {
        melhorUso = u;
        melhor = w;
      }
    }
    return melhor == null ? null : CartaFase(melhor, OrigemCarta.deNovo);
  }

  @override
  CartaFase proximaExtra({Set<String> evitar = const {}, String? outraInicialQue}) {
    if (_deck == null || _pool.isEmpty) throw StateError('abra uma fase antes de tirar palavras');
    // as que ainda vão sair da fila ficam de fora (senão a mesma palavra sairia duas vezes na fase)
    final naFila = {for (var k = _cursor; k < _fila.length; k++) _fila[k].palavra};
    final inicial = outraInicialQue == null || outraInicialQue.isEmpty ? null : outraInicialQue[0].toLowerCase();
    // a inicial vale mais que ficar fora da fila: sem candidata, o [proxima] (que solta nessa ordem)
    for (var nivel = 0; nivel < 2; nivel++) {
      final ev = nivel == 0 ? evitar : const <String>{};
      bool passa(String w) => !naFila.contains(w) &&
          !ev.contains(w) &&
          (inicial == null || w.isEmpty || w[0].toLowerCase() != inicial);
      final c = _estender(passa);
      if (c != null) {
        _pops++;
        return _servir(c);
      }
    }
    // pool pequeno (tudo ainda na fila): a de sempre
    return proxima(evitar: evitar, outraInicialQue: outraInicialQue);
  }

  CartaFase _servir(CartaFase c) {
    _ultimaTirada = c.palavra;
    _servidasNaFase.add(c.palavra);
    _usoEm[c.palavra] = ++_uso;
    return c;
  }

  /// UMA chamada por ocorrência terminada (digitada/destruída, ou perdida). [msPorLetra]: o tempo da
  /// palavra ([CronometroPalavra.msPorLetra]), null quando não foi medido.
  void registrar(String palavra, {int erros = 0, bool perdeu = false, double? msPorLetra}) {
    _seq++;
    final h = _hist[palavra] ??= _Hist();
    h.ocorrencias++;
    h.ultimaSeq = _seq;
    h.ultimaErros = max(0, erros);
    h.ultimaPerdeu = perdeu;
    final ms = msPorLetra;
    if (!perdeu && ms != null && !ms.isNaN) {
      final v = ms.clamp(minMsPorLetra, maxMsPorLetra).toDouble();
      h.ultimaMs = v;
      h.amostras.add(v);
      _todasAmostras.add(v);
      _medianaSuja = true;
    } else {
      h.ultimaMs = null;
    }
    _usoEm[palavra] = ++_uso;
    if (_focoAtivo.contains(palavra)) _focoVisto.add(palavra);
    if (reenfileirarNaFase && (perdeu || erros >= errosParaReenfileirar)) _reenfileirar(palavra);
  }

  /// A de revisão 🔁 que a pessoa PULOU (no Turismo, a outra saída do portal: a 1ª letra escolhe a faixa):
  /// volta ainda nesta fase, 3–5 tiradas depois (no Turismo, como combustível) — fugir da saída não livra a
  /// palavra. Não conta como ocorrência (continua candidata a revisão na fase seguinte).
  void devolver(String palavra) => _reenfileirar(palavra);

  void _reenfileirar(String palavra) {
    if (!_poolSet.contains(palavra) ||
        (_reenfNaFase[palavra] ?? 0) >= maxReenfileirarPorFase ||
        _reenf.any((e) => e.$1 == palavra)) {
      return;
    }
    _reenfNaFase[palavra] = (_reenfNaFase[palavra] ?? 0) + 1;
    _reenf.add((palavra, _pops + atrasoMin + _rnd.nextInt(atrasoMax - atrasoMin + 1)));
  }

  /// A mediana (ms por letra) da partida; null com menos de [amostraMinima] amostras.
  double? get mediana {
    if (_todasAmostras.length < amostraMinima) return null;
    if (_medianaSuja) {
      final s = [..._todasAmostras]..sort();
      final n = s.length;
      _medianaCache = n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
      _medianaSuja = false;
    }
    return _medianaCache;
  }

  /// As candidatas a revisão da partida (caiu/errou, depois as lentas), da mais urgente — o "de novo"
  /// passa pra partida seguinte como [BaralhoFases.new] `dificeis`.
  List<String> pendentes() => [
        for (final c in _candidatas(_hist.keys))
          if (c.origem != OrigemCarta.dificil) c.palavra,
      ];

  /// As MUITO lentas (> [fatorMuitoLenta] × a mediana final em [ocorrenciasMuitoLenta]+ ocorrências) que
  /// ainda não foram entregues; marca como entregues (o banco recebe cada uma uma vez por partida).
  Set<String> tirarLentasParaBanco() {
    final m = mediana;
    if (m == null) return const {};
    final r = <String>{};
    for (final e in _hist.entries) {
      if (_lentasEnviadas.contains(e.key)) continue;
      final muito = e.value.amostras.where((a) => a > fatorMuitoLenta * m).length;
      if (muito >= ocorrenciasMuitoLenta) r.add(e.key);
    }
    _lentasEnviadas.addAll(r);
    return r;
  }
}

/// O tempo de digitar UMA palavra, sem as pausas. Relógio injetado (testes).
class CronometroPalavra {
  final int Function() _agoraMs;

  CronometroPalavra({int Function()? agoraMs}) : _agoraMs = agoraMs ?? _relogio;

  static int _relogio() => DateTime.now().millisecondsSinceEpoch;

  bool _rodando = false;
  bool _pausado = false;
  int _inicio = 0;
  int _acumulado = 0;

  /// Começou (pausado ou não) e ainda não terminou.
  bool get rodando => _rodando;

  /// Começa a contar (nada se já estiver contando).
  void iniciar() {
    if (_rodando) return;
    _rodando = true;
    _pausado = false;
    _acumulado = 0;
    _inicio = _agoraMs();
  }

  /// Congela (nada se parado ou já pausado).
  void pausar() {
    if (!_rodando || _pausado) return;
    _acumulado += _agoraMs() - _inicio;
    _pausado = true;
  }

  void retomar() {
    if (!_rodando || !_pausado) return;
    _inicio = _agoraMs();
    _pausado = false;
  }

  /// Para e devolve ms / max(1, letras − 1) (o relógio começa na 1ª tecla: são letras − 1 intervalos),
  /// ou null se nunca começou. Zera.
  double? msPorLetra(String palavra) {
    if (!_rodando) {
      zerar();
      return null;
    }
    final total = _acumulado + (_pausado ? 0 : _agoraMs() - _inicio);
    zerar();
    return total / max(1, palavra.runes.length - 1);
  }

  void zerar() {
    _rodando = false;
    _pausado = false;
    _acumulado = 0;
    _inicio = 0;
  }
}
