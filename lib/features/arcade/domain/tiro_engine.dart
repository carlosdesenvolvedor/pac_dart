import 'dart:math';

import 'baralho_fases.dart';
import 'palavras_dart.dart';

/// Uma palavra caindo na Chuva de Código. Posições em fração da arena
/// (x: 0 esquerda → 1 direita; y: 0 topo → 1 chão).
class PalavraCaindo {
  final int id;
  final String texto;

  /// Palavra dourada: vale 4x os pontos.
  final bool ouro;

  /// Inglês: veio do baralho pra revisar 🔁 (errou, deixou cair, demorou, ou do banco).
  final bool revisao;
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
    this.revisao = false,
  });
}

enum TiroResultado { avancou, destruiu, errou, nada }

/// ☄️ Chuva de Código: palavras do Dart caem; a primeira letra digitada
/// TRAVA a mira na palavra mais baixa que começa com ela, e cada letra
/// certa é um tiro do Pac. Palavra completa explode e pontua (ouro = 4x).
/// Palavra que toca o chão custa uma vida; com 3 quedas o jogo acaba.
///
/// COMBO: palavras destruídas em sequência sem NENHUM erro de tecla (nem
/// palavra no chão) multiplicam os pontos — x2 a partir da 5ª, x3 da 10ª.
class TiroEngine {
  final Random rnd;
  final List<String> curtas;
  final List<String> medias;
  final List<String> longas;

  /// Inglês: de onde sai cada palavra que nasce (o baralho da fase). Null = sorteio nas listas, como sempre.
  final FonteDePalavras? fonte;

  /// Inglês: quantas destruir em cada nível pra subir (cresce com o nível). Null = a cada 8, como sempre.
  final int Function(int nivel)? metaDoNivel;

  static const vidasIniciais = 3;
  static const nivelMaximo = 8;
  static const maxNaTela = 6;

  int vidas = vidasIniciais;
  int pontos = 0;
  int destruidas = 0;
  int erros = 0;
  int nivel = 1;

  /// Palavras seguidas sem erro (zera na tecla errada e na palavra no chão).
  int combo = 0;
  int melhorCombo = 0;

  /// Pontos da última palavra destruída (já com ouro e combo).
  int ultimoGanho = 0;

  final List<PalavraCaindo> ativas = [];
  int? alvoId;

  /// As que tocaram o chão no último [tick] (a mesma lista, esvaziada a cada tick: nada alocado por quadro).
  final List<PalavraCaindo> ultimasCaidas = [];

  int _proximoId = 0;
  int _destruidasNoNivel = 0;
  double _relogioSpawn = 999; // primeira palavra nasce no primeiro tick

  TiroEngine({
    required this.rnd,
    this.curtas = palavrasCurtas,
    this.medias = palavrasMedias,
    this.longas = palavrasLongas,
    this.fonte,
    this.metaDoNivel,
  });

  bool get fim => vidas <= 0;

  /// Multiplicador do combo atual: x1, x2 (5+ seguidas) ou x3 (10+).
  int get multiplicador => multiplicadorDoCombo(combo);

  static int multiplicadorDoCombo(int combo) => combo >= 10 ? 3 : (combo >= 5 ? 2 : 1);

  /// Quantas palavras faltam pro próximo multiplicador (0 = já no máximo).
  int get faltamProCombo => combo >= 10 ? 0 : (combo >= 5 ? 10 - combo : 5 - combo);

  PalavraCaindo? get alvo {
    for (final p in ativas) {
      if (p.id == alvoId) return p;
    }
    return null;
  }

  /// O nível da VELOCIDADE: sobe a cada 8 destruídas, como sempre — com [metaDoNivel] (o inglês, níveis de
  /// 8, 10, 12… palavras) o ritmo não fica pra trás do Dart: o baralho troca por nível, a pressa não.
  int get nivelDoRitmo => metaDoNivel == null ? nivel : min(nivelMaximo, destruidas ~/ 8 + 1);

  /// Segundos entre uma palavra e a próxima (aperta com o nível).
  double get intervaloSpawn => (3.4 - 0.22 * (nivelDoRitmo - 1)).clamp(1.6, 3.4);

  /// Fração da arena percorrida por segundo (queda ~18s → ~9s no nível 8).
  double get velocidade => 0.055 + 0.011 * (nivelDoRitmo - 1);

  /// Avança o relógio do jogo em [dt] segundos: nasce palavra, tudo cai,
  /// e o que tocar o chão custa vida.
  void tick(double dt) {
    ultimasCaidas.clear();
    if (fim) return;
    _relogioSpawn += dt;
    if (_relogioSpawn >= intervaloSpawn && ativas.length < maxNaTela) {
      _spawn();
      _relogioSpawn = 0;
    }
    for (final p in ativas) {
      p.y += velocidade * dt;
    }
    for (final p in ativas) {
      if (p.y >= 1) ultimasCaidas.add(p);
    }
    for (final p in ultimasCaidas) {
      ativas.remove(p);
      if (alvoId == p.id) alvoId = null;
      vidas--;
      combo = 0;
    }
  }

  void _spawn() {
    final f = fonte;
    if (f != null) {
      // o baralho da fase escolhe (nunca uma que já está na tela); ouro e x saem do rnd como sempre
      final c = f.proxima(evitar: {for (final a in ativas) a.texto});
      ativas.add(PalavraCaindo(
        id: _proximoId++,
        texto: c.palavra,
        revisao: c.revisao,
        ouro: rnd.nextDouble() < 0.15,
        x: 0.04 + rnd.nextDouble() * 0.92,
      ));
      return;
    }
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
        combo = 0;
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
        combo = 0;
        return (TiroResultado.errou, a);
      }
    }
    if (a.digitadas >= a.texto.length) {
      combo++;
      if (combo > melhorCombo) melhorCombo = combo;
      ultimoGanho = (10 + a.texto.length) * (a.ouro ? 4 : 1) * multiplicador;
      pontos += ultimoGanho;
      destruidas++;
      ativas.remove(a);
      alvoId = null;
      final meta = metaDoNivel;
      if (meta == null) {
        if (destruidas % 8 == 0 && nivel < nivelMaximo) nivel++;
      } else if (nivel < nivelMaximo && ++_destruidasNoNivel >= meta(nivel)) {
        nivel++;
        _destruidasNoNivel = 0;
      }
      return (TiroResultado.destruiu, a);
    }
    return (TiroResultado.avancou, a);
  }
}
