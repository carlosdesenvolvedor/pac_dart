// Os tropeços de uma partida dos jogos de digitação (Chuva, Rali, Turismo) no inglês: em que palavra a
// pessoa errou, quanto (falha 0–1 por OCORRÊNCIA da palavra) e quando vale um aviso leve na tela
// ("💡 "because" escapou 2x — anotei pra revanche"). Dart puro, sem relógio de verdade (injetado) e sem
// saber de onde as palavras vêm — o banco do aluno recebe o resumo no fim da partida.

/// O placar de tropeços de UMA partida.
class TropecosDoJogo {
  /// Relógio em ms (fixo nos testes).
  final int Function() agoraMs;

  /// No máximo [maxAvisos] avisos por partida, com pelo menos [intervaloMs] entre um e outro.
  final int maxAvisos;
  final int intervaloMs;

  /// Soma de falha (de várias ocorrências) e ocorrências com falha que fazem a palavra merecer um aviso.
  static const somaDoAviso = 1.5;
  static const ocorrenciasDoAviso = 2;

  TropecosDoJogo({int Function()? agoraMs, this.maxAvisos = 2, this.intervaloMs = 30000})
      : agoraMs = agoraMs ?? _relogio;

  static int _relogio() => DateTime.now().millisecondsSinceEpoch;

  final Map<String, int> _vistas = {};
  final Map<String, int> _erros = {};
  final Map<String, double> _somas = {};
  final Set<String> _avisadas = {};
  int _avisos = 0;
  int? _ultimoAvisoMs;

  /// A palavra saiu resolvida (destruída, digitada, portal passado limpo).
  void vista(String w) => _vistas[w] = (_vistas[w] ?? 0) + 1;

  /// Uma ocorrência de [w] com falha [f] (0 = limpa, 1 = errou de vez). Chame UMA vez por ocorrência.
  void falha(String w, double f) {
    final v = f.isNaN ? 0.0 : f.clamp(0.0, 1.0).toDouble();
    if (v <= 0) return;
    _erros[w] = (_erros[w] ?? 0) + 1;
    _somas[w] = (_somas[w] ?? 0) + v;
  }

  /// [w] merece o aviso agora? Devolve a própria palavra UMA vez por partida, quando a soma de falha chega
  /// a [somaDoAviso] em [ocorrenciasDoAviso]+ ocorrências — respeitando [maxAvisos] e [intervaloMs].
  /// [pode] falso (largada 3-2-1, pausa) segura o aviso para a próxima chance.
  String? aviso(String w, {bool pode = true}) {
    if (!pode || _avisadas.contains(w) || _avisos >= maxAvisos) return null;
    if ((_somas[w] ?? 0) < somaDoAviso || (_erros[w] ?? 0) < ocorrenciasDoAviso) return null;
    final agora = agoraMs();
    final ultimo = _ultimoAvisoMs;
    if (ultimo != null && agora - ultimo < intervaloMs) return null;
    _avisadas.add(w);
    _avisos++;
    _ultimoAvisoMs = agora;
    return w;
  }

  /// Quantas vezes [w] escapou (ocorrências com falha) nesta partida.
  int vezes(String w) => _erros[w] ?? 0;

  /// Palavra → (vistas, ocorrências com falha).
  Map<String, (int, int)> get stats => {
        for (final w in {..._vistas.keys, ..._erros.keys}) w: (_vistas[w] ?? 0, _erros[w] ?? 0),
      };

  /// Palavra → falha da partida (a soma das ocorrências, no máximo 1) — o que vai para o banco.
  Map<String, double> get falhas => {for (final e in _somas.entries) e.key: e.value > 1 ? 1.0 : e.value};

  /// Palavra → soma das falhas SEM teto (o que a oferta "treinar só elas" compara com 1,5).
  Map<String, double> get somas => Map.unmodifiable(_somas);

  /// As palavras com soma ≥ [min], da que mais escapou para a que menos (empate: mais ocorrências, depois
  /// a ordem alfabética).
  List<String> dificeis({double min = 1.0}) => [
        for (final e in _somas.entries)
          if (e.value >= min) e.key,
      ]..sort((a, b) {
          final s = _somas[b]!.compareTo(_somas[a]!);
          if (s != 0) return s;
          final o = vezes(b).compareTo(vezes(a));
          return o != 0 ? o : a.compareTo(b);
        });

  bool get vazio => _vistas.isEmpty && _erros.isEmpty;
}
