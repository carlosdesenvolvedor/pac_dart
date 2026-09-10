import 'dart:math';

import 'desafio.dart';

/// Peso de cada nível de desafio numa fase da campanha: a fase 1 aquece só
/// com o básico, a 2 mistura, a 3 sobe pro intermediário/avançado e daí em
/// diante os chefões dominam (mas o nível 2 ainda aparece pra respirar).
Map<int, double> pesosDaFase(int fase) => switch (fase) {
      <= 1 => const {1: 1.0},
      2 => const {1: 0.4, 2: 0.6},
      3 => const {2: 0.5, 3: 0.5},
      _ => const {2: 0.3, 3: 0.7},
    };

/// Baralho de campanha: entrega desafios no nível certo da fase e NÃO
/// repete carta enquanto o nível não esgotar (aí recicla só aquele nível).
///
/// Antes, cada fase sorteava do banco inteiro ordenado por nível — e como
/// uma fase gasta poucas cartas, o jogador só via o nível 1 pra sempre.
class Baralho<T> {
  final Random rnd;
  final List<T> banco;
  final int Function(T) nivelDe;
  final Set<T> _vistos = {};

  Baralho({required this.rnd, required this.banco, required this.nivelDe});

  /// Quantas cartas o baralho já entregou nesta partida (sem contar reciclagem).
  int get vistos => _vistos.length;

  /// Próxima carta da [fase]. Sorteia o nível pelos pesos da fase (só entre
  /// níveis que ainda têm carta inédita); se todos esgotaram, recicla os
  /// níveis da fase e sorteia de novo.
  T proximo(int fase) {
    final pesos = pesosDaFase(fase);
    var candidatosPorNivel = _ineditosPorNivel(pesos.keys);
    if (candidatosPorNivel.isEmpty) {
      _vistos.removeWhere((c) => pesos.containsKey(nivelDe(c)));
      candidatosPorNivel = _ineditosPorNivel(pesos.keys);
    }
    if (candidatosPorNivel.isEmpty) {
      // o banco não tem NENHUMA carta desses níveis: vale qualquer uma
      return banco[rnd.nextInt(banco.length)];
    }
    final nivel = _sorteiaNivel(pesos, candidatosPorNivel.keys);
    final cartas = candidatosPorNivel[nivel]!;
    final carta = cartas[rnd.nextInt(cartas.length)];
    _vistos.add(carta);
    return carta;
  }

  /// [quantidade] cartas da [fase], ordenadas do nível mais baixo pro mais
  /// alto — a fase esquenta aos poucos.
  List<T> sortear(int quantidade, int fase) {
    final lote = [for (var i = 0; i < quantidade; i++) proximo(fase)];
    lote.sort((a, b) => nivelDe(a).compareTo(nivelDe(b))); // sort é estável
    return lote;
  }

  Map<int, List<T>> _ineditosPorNivel(Iterable<int> niveis) {
    final mapa = <int, List<T>>{};
    for (final n in niveis) {
      final lista = [
        for (final c in banco)
          if (nivelDe(c) == n && !_vistos.contains(c)) c,
      ];
      if (lista.isNotEmpty) mapa[n] = lista;
    }
    return mapa;
  }

  int _sorteiaNivel(Map<int, double> pesos, Iterable<int> disponiveis) {
    final validos = [for (final n in disponiveis) n]..sort();
    final total = validos.fold<double>(0, (s, n) => s + pesos[n]!);
    var sorteio = rnd.nextDouble() * total;
    for (final n in validos) {
      sorteio -= pesos[n]!;
      if (sorteio <= 0) return n;
    }
    return validos.last;
  }
}

/// Baralho dos desafios de múltipla escolha (lógica ou sintaxe): cada carta
/// sai com as opções embaralhadas, mas a "vista" é a carta original.
class BaralhoDesafios {
  final Baralho<Desafio> _baralho;
  final Random _rnd;

  BaralhoDesafios({
    required Random rnd,
    required TipoDesafio tipo,
    required List<Desafio> banco,
  })  : _rnd = rnd,
        _baralho = Baralho(
          rnd: rnd,
          banco: [for (final d in banco) if (d.tipo == tipo) d],
          nivelDe: (d) => d.nivel,
        );

  Desafio proximo(int fase) => _baralho.proximo(fase).embaralhado(_rnd);

  List<Desafio> sortear(int quantidade, int fase) =>
      [for (final d in _baralho.sortear(quantidade, fase)) d.embaralhado(_rnd)];
}

/// Baralho do Caça-Bug (mesma regra de níveis e de não repetir).
class BaralhoBugs {
  final Baralho<DesafioBug> _baralho;

  BaralhoBugs({required Random rnd, required List<DesafioBug> banco})
      : _baralho = Baralho(rnd: rnd, banco: banco, nivelDe: (b) => b.nivel);

  List<DesafioBug> sortear(int quantidade, int fase) => _baralho.sortear(quantidade, fase);
}
