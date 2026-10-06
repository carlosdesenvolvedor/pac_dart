import 'package:equatable/equatable.dart';

import 'revisao.dart';

/// Quanto da frase em inglês aparece enquanto se digita (a "escada de
/// apoio" — dossiê 01 §5.1). A tradução em português fica SEMPRE em cima.
enum ModoFrase {
  /// N0 — a frase inteira à vista: ouvir e copiar prestando atenção.
  ver,

  /// N1 — só a 1ª letra de cada palavra (o resto vira tracinho).
  pistas,

  /// N2 — só os tracinhos: o tamanho de cada palavra e a pontuação.
  esqueleto,

  /// N3 — nada do inglês: só a tradução. Erro na mesma letra 2× revela.
  memoria;

  String get rotulo => switch (this) {
        ModoFrase.ver => 'Copie',
        ModoFrase.pistas => 'Iniciais',
        ModoFrase.esqueleto => 'Esqueleto',
        ModoFrase.memoria => 'De memória',
      };

  String get emoji => switch (this) {
        ModoFrase.ver => '👀',
        ModoFrase.pistas => '🔍',
        ModoFrase.esqueleto => '▁',
        ModoFrase.memoria => '🧠',
      };

  /// Digitação de memória: gera nota, correção tolerante e áudio só depois.
  bool get deMemoria => this != ModoFrase.ver;
}

/// Os degraus de uma frase nova na lição: D1 conhecer (cópia) → D2
/// iniciais → D3 esqueleto → D4 de memória → D5 prova (de memória, na
/// rodada final embaralhada).
enum Degrau {
  conhecer(ModoFrase.ver),
  iniciais(ModoFrase.pistas),
  esqueleto(ModoFrase.esqueleto),
  memoria(ModoFrase.memoria),
  prova(ModoFrase.memoria);

  const Degrau(this.modo);
  final ModoFrase modo;
}

/// Um passo da lição: digitar a frase [frase] no [modo].
class PassoFila extends Equatable {
  final int frase;
  final Degrau degrau;

  /// Cópia de correção logo depois de um erro (não conta como passada —
  /// é a única vez em que a mesma frase vem duas vezes seguidas).
  final bool correcao;

  /// Quantas vezes a frase já foi digitada antes deste passo + 1.
  final int vez;

  const PassoFila(this.frase, this.degrau, {this.correcao = false, this.vez = 1});

  ModoFrase get modo => correcao ? ModoFrase.ver : degrau.modo;

  /// Primeira aparição da frase na lição (o áudio toca ANTES de digitar).
  bool get estreia => degrau == Degrau.conhecer && !correcao;

  @override
  List<Object?> get props => [frase, degrau, correcao, vez];

  @override
  String toString() => '${String.fromCharCode(65 + frase % 26)}${correcao ? 'c' : degrau.index + 1}';
}

class _EstadoFrase {
  Degrau degrau = Degrau.conhecer;
  bool introduzida = false;
  bool concluida = false;

  /// Retentativa da prova depois de errar (entra como "vencida", não sorteada).
  bool retentativa = false;
  ResultadoRevisao? ultimo;
  int venceEm = 0;
  int vezes = 0;
  int ultimoPasso = -100;
}

/// A fila de uma lição de frases novas (dossiê 01 §5.2): cada frase sobe
/// a escada D1→D5, SEMPRE intercalada com as outras (as repetições
/// voltam depois de 3, 5 e 7 outras digitações, e a prova vem na rodada
/// final). Erro em digitação de memória → cópia de correção na hora e a
/// frase desce um degrau. Pura e determinística (testável).
class FilaLicao {
  /// Outras digitações entre um degrau e o seguinte.
  static const lags = {Degrau.conhecer: 3, Degrau.iniciais: 5, Degrau.esqueleto: 7};

  /// Mínimo de digitações entre o D4 e a prova.
  static const lagProva = 8;

  /// Volta depois de errar.
  static const lagErro = 3;

  /// Máximo de digitações da mesma frase no dia, contando correções (o
  /// dossiê fala em 7; com 8 cabe a escada inteira com um erro no D4:
  /// D1 D2 D3 D4✗ cópia D3 D4 D5).
  static const teto = 8;

  final int n;
  final List<_EstadoFrase> _f;
  int _passo = 0;
  int _semente;
  int? _correcao;
  PassoFila? _atual;

  /// Resultado da 1ª prova (D5) de cada frase — a nota da lição.
  final Map<int, ResultadoRevisao> primeiraProva = {};

  /// Frases que estouraram o teto do dia sem passar na prova.
  final Set<int> dificeis = {};

  FilaLicao(this.n, {int semente = 1})
      : _f = List.generate(n, (_) => _EstadoFrase()),
        _semente = semente == 0 ? 1 : semente {
    _atual = _escolher();
  }

  /// O passo da vez (null = a lição acabou).
  PassoFila? get atual => _atual;
  bool get terminou => _atual == null;

  /// Digitações feitas até aqui.
  int get feitos => _passo;

  /// A frase [f] já passou na prova (ou saiu pelo teto) nesta lição.
  bool concluida(int f) => f >= 0 && f < n && _f[f].concluida;

  /// Estimativa de digitações que faltam (para a barra de progresso).
  int get restantes {
    var r = _correcao == null ? 0 : 1;
    for (final e in _f) {
      if (!e.concluida) r += Degrau.values.length - e.degrau.index;
    }
    return r;
  }

  /// Registra como foi o passo atual ([r] = null para cópia) e avança.
  void registrar(ResultadoRevisao? r, {bool semCorrecao = false}) {
    final p = _atual;
    if (p == null) return;
    final e = _f[p.frase];
    e.vezes++;
    e.ultimoPasso = _passo;
    final agora = _passo;
    _passo++;

    if (p.correcao) {
      _correcao = null;
    } else {
      if (r != null) e.ultimo = r;
      _agendar(p, e, r ?? ResultadoRevisao.acertou, agora, semCorrecao: semCorrecao);
    }
    if (!e.concluida && e.vezes >= teto) {
      if (_correcao == p.frase) _correcao = null; // o feedback na tela basta
      // estourou o teto do dia: sai da lição e volta amanhã na revisão;
      // só é "difícil" se a última tentativa de memória ainda foi errada
      e.concluida = true;
      if (e.ultimo == ResultadoRevisao.errou) dificeis.add(p.frase);
    }
    _atual = _escolher();
  }

  void _agendar(PassoFila p, _EstadoFrase e, ResultadoRevisao r, int agora, {required bool semCorrecao}) {
    final errou = r == ResultadoRevisao.errou && p.degrau != Degrau.conhecer;
    if (p.degrau == Degrau.prova && !primeiraProva.containsKey(p.frase)) primeiraProva[p.frase] = r;
    if (errou) {
      if (!semCorrecao) _correcao = p.frase;
      e.degrau = switch (p.degrau) {
        Degrau.iniciais || Degrau.esqueleto => Degrau.iniciais,
        Degrau.memoria => Degrau.esqueleto,
        Degrau.prova => Degrau.prova,
        Degrau.conhecer => Degrau.iniciais,
      };
      e.retentativa = e.degrau == Degrau.prova;
      e.venceEm = agora + lagErro + 1;
      return;
    }
    switch (p.degrau) {
      case Degrau.conhecer:
      case Degrau.iniciais:
      case Degrau.esqueleto:
        e.venceEm = agora + lags[p.degrau]! + 1;
        e.degrau = Degrau.values[p.degrau.index + 1];
      case Degrau.memoria:
        if (r == ResultadoRevisao.hesitou) {
          e.venceEm = agora + 5 + 1; // repete o D4 antes da prova
        } else {
          e.degrau = Degrau.prova;
          e.retentativa = false;
          e.venceEm = agora + lagProva + 1;
        }
      case Degrau.prova:
        e.concluida = true;
    }
  }

  /// Pseudo-aleatório determinístico (sorteio da rodada final).
  int _sorteia(int faixa) {
    _semente = (_semente * 1103515245 + 12345) & 0x7fffffff;
    return _semente % faixa;
  }

  PassoFila? _passoDe(int f) {
    final e = _f[f];
    return PassoFila(f, e.degrau, vez: e.vezes + 1);
  }

  PassoFila? _escolher() {
    final c = _correcao;
    if (c != null) return PassoFila(c, _f[c].degrau, correcao: true, vez: _f[c].vezes + 1);
    final p = _passo;
    // 1. a que venceu há mais tempo (D2–D4 e as retentativas da prova)
    int? melhor;
    for (var i = 0; i < n; i++) {
      final e = _f[i];
      if (!e.introduzida || e.concluida || e.venceEm > p) continue;
      if (e.degrau == Degrau.prova && !e.retentativa) continue;
      if (melhor == null || e.venceEm < _f[melhor].venceEm) melhor = i;
    }
    if (melhor != null) return _passoDe(melhor);
    // 2. frase nova
    for (var i = 0; i < n; i++) {
      if (!_f[i].introduzida) {
        _f[i].introduzida = true;
        return PassoFila(i, Degrau.conhecer, vez: 1);
      }
    }
    // 3. prova da rodada final, sorteada entre as prontas
    final prontas = [
      for (var i = 0; i < n; i++)
        if (!_f[i].concluida && _f[i].degrau == Degrau.prova && _f[i].venceEm <= p) i,
    ];
    if (prontas.isNotEmpty) return _passoDe(prontas[_sorteia(prontas.length)]);
    // 5. a pendente mais próxima, evitando repetir a de agora há pouco
    final pendentes = [for (var i = 0; i < n; i++) if (!_f[i].concluida) i];
    if (pendentes.isEmpty) return null;
    int? folga, qualquer;
    for (final i in pendentes) {
      final e = _f[i];
      if (qualquer == null || e.venceEm < _f[qualquer].venceEm) qualquer = i;
      if (p - e.ultimoPasso > 2 && (folga == null || e.venceEm < _f[folga].venceEm)) folga = i;
    }
    return _passoDe(folga ?? qualquer!);
  }

  /// Nota da lição (0..10) pela 1ª prova de cada frase: limpa vale 1, com
  /// tropeço meio, errada ou sem prova 0.
  int get nota {
    if (n == 0) return 0;
    var pontos = 0.0;
    for (var i = 0; i < n; i++) {
      final r = primeiraProva[i];
      if (r == ResultadoRevisao.acertou) pontos += 1;
      if (r == ResultadoRevisao.hesitou) pontos += .5;
    }
    return (pontos * 10 / n).round();
  }
}

/// O que aparece de cada caractere ainda NÃO digitado.
enum Mostra { letra, tracinho, nada }

/// Máscara do que aparece da frase no [modo] (por caractere, antes de ser
/// digitado). Pistas: a inicial de cada palavra e a pontuação; esqueleto:
/// tracinhos no lugar das letras e a pontuação; memória: nada.
List<Mostra> mascaraDaFrase(String frase, ModoFrase modo) {
  final m = List<Mostra>.filled(frase.length, Mostra.letra);
  if (modo == ModoFrase.ver) return m;
  if (modo == ModoFrase.memoria) return List<Mostra>.filled(frase.length, Mostra.nada);
  var inicioPalavra = true;
  for (var i = 0; i < frase.length; i++) {
    final c = frase[i];
    if (RegExp(r'[A-Za-z0-9]').hasMatch(c)) {
      m[i] = modo == ModoFrase.pistas && inicioPalavra ? Mostra.letra : Mostra.tracinho;
      inicioPalavra = false;
    } else {
      // apóstrofo/hífen no meio da palavra (don't, well-known) não reinicia
      inicioPalavra = c == ' ';
    }
  }
  return m;
}
