import 'dart:math' as math;

/// O formato da boca num instante da fala (os visemas do Rhubarb Lip Sync, a
/// convenção de animação 2D da Hanna-Barbera):
///
/// - [x] parada (sorrisinho de quem escuta)
/// - [a] fechada apertada: **M, B, P**
/// - [b] quase fechada com dentes: **K, S, T, EE**…
/// - [c] aberta: **EH, AE**
/// - [d] bem aberta: **AA**
/// - [e] arredondada: **AO, ER**
/// - [f] biquinho: **UW, OW, W**
/// - [g] dentes no lábio: **F, V**
/// - [h] língua para cima: **L**
enum Visema { x, a, b, c, d, e, f, g, h }

/// A boca ao longo de uma fala: cada visema vale do seu instante até o próximo.
class TrilhaBoca {
  /// Instantes (s, crescentes) e o visema que começa em cada um.
  final List<double> tempos;
  final List<Visema> visemas;

  const TrilhaBoca._(this.tempos, this.visemas);

  static const vazia = TrilhaBoca._([], []);

  bool get isEmpty => tempos.isEmpty;

  /// Duração da fala (o instante do último visema, que é a boca parada).
  double get duracao => tempos.isEmpty ? 0 : tempos.last;

  /// O formato compacto do `bocas.json` (tools/ingles/bocas_rhubarb.py): "0X 9B 15E 41C…" — centésimos de
  /// segundo e a letra do visema.
  factory TrilhaBoca.compacta(String s) {
    final tempos = <double>[];
    final visemas = <Visema>[];
    for (final par in s.split(' ')) {
      if (par.length < 2) continue;
      final t = int.tryParse(par.substring(0, par.length - 1));
      final v = visemaDaLetra(par.substring(par.length - 1));
      if (t == null || v == null) continue;
      tempos.add(t / 100);
      visemas.add(v);
    }
    return TrilhaBoca._(tempos, visemas);
  }

  /// A boca no segundo [t] da fala (antes do começo e depois do fim: parada).
  Visema em(double t) {
    if (tempos.isEmpty || t < tempos.first || t >= tempos.last) return Visema.x;
    // busca binária: o último instante <= t
    var lo = 0, hi = tempos.length - 1;
    while (lo < hi) {
      final m = (lo + hi + 1) >> 1;
      if (tempos[m] <= t) {
        lo = m;
      } else {
        hi = m - 1;
      }
    }
    return visemas[lo];
  }

  /// Uma boca aproximada só pelo TEXTO, para a voz sintética do navegador (que não entrega o áudio):
  /// cada letra vira um visema e as palavras se repartem em [segPorPalavra] cada.
  factory TrilhaBoca.doTexto(String frase, {required double segPorPalavra, double inicio = .15}) {
    final palavras = RegExp(r"[A-Za-z']+").allMatches(frase).map((m) => m.group(0)!.toLowerCase()).toList();
    final tempos = <double>[];
    final visemas = <Visema>[];
    var t = inicio;
    void poe(double tempo, Visema v) {
      if (visemas.isNotEmpty && visemas.last == v) return;
      tempos.add(double.parse(tempo.toStringAsFixed(3)));
      visemas.add(v);
    }

    poe(0, Visema.x);
    for (final p in palavras) {
      final sons = _sonsDaPalavra(p);
      // a palavra ocupa ~85% do tempo dela; o resto é a pausinha entre palavras
      final passo = segPorPalavra * .85 / math.max(1, sons.length);
      for (final v in sons) {
        poe(t, v);
        t += passo;
      }
      t += segPorPalavra * .15;
      poe(t - segPorPalavra * .1, Visema.a);
    }
    poe(t, Visema.x);
    return TrilhaBoca._(tempos, visemas);
  }

  /// Letras (e alguns pares) → visemas, sem repetir o mesmo seguido.
  static List<Visema> _sonsDaPalavra(String p) {
    final r = <Visema>[];
    var i = 0;
    while (i < p.length) {
      final dois = i + 1 < p.length ? p.substring(i, i + 2) : '';
      Visema? v;
      var anda = 1;
      switch (dois) {
        case 'oo' || 'ou' || 'ow':
          v = Visema.f;
          anda = 2;
        case 'th':
          v = Visema.b;
          anda = 2;
        case 'ee' || 'ea':
          v = Visema.b;
          anda = 2;
      }
      v ??= switch (p[i]) {
        'm' || 'b' || 'p' => Visema.a,
        'f' || 'v' => Visema.g,
        'l' => Visema.h,
        'a' => Visema.d,
        'e' || 'i' || 'y' => Visema.c,
        'o' => Visema.e,
        'u' || 'w' || 'q' => Visema.f,
        "'" => null,
        _ => Visema.b,
      };
      if (v != null && (r.isEmpty || r.last != v)) r.add(v);
      i += anda;
    }
    return r;
  }
}

/// A letra do Rhubarb (A–H, X) → [Visema]; null = letra desconhecida.
Visema? visemaDaLetra(String letra) => switch (letra.trim().toUpperCase()) {
  'X' => Visema.x,
  'A' => Visema.a,
  'B' => Visema.b,
  'C' => Visema.c,
  'D' => Visema.d,
  'E' => Visema.e,
  'F' => Visema.f,
  'G' => Visema.g,
  'H' => Visema.h,
  _ => null,
};
