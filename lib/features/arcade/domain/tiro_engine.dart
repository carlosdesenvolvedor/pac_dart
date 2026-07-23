import 'dart:math';

import 'palavras_dart.dart';

/// Uma palavra caindo na Chuva de Código. Posições em fração da arena
/// (x: 0 esquerda → 1 direita; y: 0 topo → 1 chão).
class PalavraCaindo {
  final int id;
  final String texto;

  /// Palavra dourada: vale 4x os pontos.
  final bool ouro;
  final double x;
  double y;

  /// Letras já atingidas pelos tiros do Pac.
  int digitadas = 0;

  PalavraCaindo({
    required this.id,
    required this.texto,
    required this.x,
    this.y = 0,
    this.ouro = false,
  });
}

enum TiroResultado { avancou, destruiu, errou, nada }

/// ☄️ Chuva de Código: palavras do Dart caem; a primeira letra digitada
/// TRAVA a mira na palavra mais baixa que começa com ela, e cada letra
/// certa é um tiro do Pac. Palavra completa explode e pontua (ouro = 4x).
/// Palavra que toca o chão custa uma vida; com 3 quedas o jogo acaba.
class TiroEngine {
  final Random rnd;
  final List<String> curtas;
  final List<String> medias;
  final List<String> longas;

  static const vidasIniciais = 3;
  static const nivelMaximo = 8;
  static const maxNaTela = 6;

  int vidas = vidasIniciais;
  int pontos = 0;
  int destruidas = 0;
  int erros = 0;
  int nivel = 1;

  final List<PalavraCaindo> ativas = [];
  int? alvoId;

  int _proximoId = 0;
  double _relogioSpawn = 999; // primeira palavra nasce no primeiro tick

  TiroEngine({
    required this.rnd,
    this.curtas = palavrasCurtas,
    this.medias = palavrasMedias,
    this.longas = palavrasLongas,
  });

  bool get fim => vidas <= 0;

  PalavraCaindo? get alvo {
    for (final p in ativas) {
      if (p.id == alvoId) return p;
    }
    return null;
  }

  /// Segundos entre uma palavra e a próxima (aperta com o nível).
  double get intervaloSpawn => (3.4 - 0.22 * (nivel - 1)).clamp(1.6, 3.4);

  /// Fração da arena percorrida por segundo (queda ~18s → ~9s no nível 8).
  double get velocidade => 0.055 + 0.011 * (nivel - 1);

  /// Avança o relógio do jogo em [dt] segundos: nasce palavra, tudo cai,
  /// e o que tocar o chão custa vida.
  void tick(double dt) {
    if (fim) return;
    _relogioSpawn += dt;
    if (_relogioSpawn >= intervaloSpawn && ativas.length < maxNaTela) {
      _spawn();
      _relogioSpawn = 0;
    }
    for (final p in ativas) {
      p.y += velocidade * dt;
    }
    final caidas = [
      for (final p in ativas)
        if (p.y >= 1) p,
    ];
    for (final p in caidas) {
      ativas.remove(p);
      if (alvoId == p.id) alvoId = null;
      vidas--;
    }
  }

  void _spawn() {
    ativas.add(PalavraCaindo(
      id: _proximoId++,
      texto: _sorteiaTexto(),
      ouro: rnd.nextDouble() < 0.15,
      x: 0.04 + rnd.nextDouble() * 0.92,
    ));
  }

  String _sorteiaTexto() {
    final pool = switch (nivel) {
      1 => curtas,
      2 => [...curtas, ...medias],
      _ => [...curtas, ...medias, ...longas],
    };
    // evita palavra repetida na tela (duas iguais confundem a mira)
    for (var t = 0; t < 30; t++) {
      final p = pool[rnd.nextInt(pool.length)];
      if (!ativas.any((a) => a.texto == p)) return p;
    }
    return pool[rnd.nextInt(pool.length)];
  }

  /// Uma tecla do jogador. Devolve o que houve e a palavra atingida
  /// (null quando errou ou não havia alvo possível).
  (TiroResultado, PalavraCaindo?) teclar(String ch) {
    if (fim) return (TiroResultado.nada, null);
    var a = alvo;
    if (a == null) {
      // trava a mira: entre as que começam com a letra, a mais BAIXA (urgente)
      final candidatas = [
        for (final p in ativas)
          if (p.texto.startsWith(ch)) p,
      ];
      if (candidatas.isEmpty) {
        erros++;
        return (TiroResultado.errou, null);
      }
      candidatas.sort((p, q) => q.y.compareTo(p.y));
      a = candidatas.first;
      alvoId = a.id;
      a.digitadas = 1;
    } else {
      if (a.digitadas < a.texto.length && a.texto[a.digitadas] == ch) {
        a.digitadas++;
      } else {
        erros++;
        return (TiroResultado.errou, a);
      }
    }
    if (a.digitadas >= a.texto.length) {
      pontos += (10 + a.texto.length) * (a.ouro ? 4 : 1);
      destruidas++;
      ativas.remove(a);
      alvoId = null;
      if (destruidas % 8 == 0 && nivel < nivelMaximo) nivel++;
      return (TiroResultado.destruiu, a);
    }
    return (TiroResultado.avancou, a);
  }
}
