import 'dart:math';

import 'package:equatable/equatable.dart';

/// Baralhos do Arcade: lógica (prever o resultado — Corrida do Código) e
/// sintaxe (completar a peça que falta — Gol de Dart).
enum TipoDesafio { logica, sintaxe }

/// Um desafio de múltipla escolha dos joguinhos do Arcade.
class Desafio extends Equatable {
  final String pergunta;

  /// Trecho mostrado com destaque de sintaxe (vazio = só a pergunta).
  final String codigo;
  final List<String> opcoes;
  final int certa;

  /// Por que a resposta é essa — aparece quando o jogador erra.
  final String explica;

  /// 1 (básico) a 3 (avançado) — os jogos sobem o nível aos poucos.
  final int nivel;
  final TipoDesafio tipo;

  const Desafio({
    required this.pergunta,
    this.codigo = '',
    required this.opcoes,
    required this.certa,
    required this.explica,
    required this.nivel,
    required this.tipo,
  });

  /// Reordena as opções — a certa muda de lugar a cada partida.
  Desafio embaralhado(Random rnd) {
    final ordem = List.generate(opcoes.length, (i) => i)..shuffle(rnd);
    return Desafio(
      pergunta: pergunta,
      codigo: codigo,
      opcoes: [for (final i in ordem) opcoes[i]],
      certa: ordem.indexOf(certa),
      explica: explica,
      nivel: nivel,
      tipo: tipo,
    );
  }

  @override
  List<Object?> get props => [pergunta, codigo, opcoes, certa, explica, nivel, tipo];
}

/// Um trecho com exatamente UMA linha defeituosa (jogo Caça-Bug).
class DesafioBug extends Equatable {
  /// O que o código DEVERIA fazer (a missão da rodada).
  final String missao;
  final List<String> linhas;
  final int linhaComBug;
  final String explica;
  final int nivel;

  const DesafioBug({
    required this.missao,
    required this.linhas,
    required this.linhaComBug,
    required this.explica,
    required this.nivel,
  });

  @override
  List<Object?> get props => [missao, linhas, linhaComBug, explica, nivel];
}

/// Sorteia [quantidade] desafios de um [tipo], embaralhando dentro de cada
/// nível mas mantendo a escadinha fácil → difícil (o jogo esquenta aos poucos).
/// Se a quantidade passa do banco, o baralho recomeça.
List<Desafio> sortearDesafios({
  required TipoDesafio tipo,
  required int quantidade,
  required Random rnd,
  required List<Desafio> banco,
}) {
  final doTipo = banco.where((d) => d.tipo == tipo).toList();
  final fila = <Desafio>[];
  while (fila.length < quantidade) {
    final rodada = [...doTipo]..shuffle(rnd);
    rodada.sort((a, b) => a.nivel.compareTo(b.nivel)); // sort é estável
    fila.addAll(rodada.map((d) => d.embaralhado(rnd)));
  }
  return fila.take(quantidade).toList();
}

/// Sorteia [quantidade] rodadas do Caça-Bug na mesma escadinha de nível.
List<DesafioBug> sortearBugs({
  required int quantidade,
  required Random rnd,
  required List<DesafioBug> banco,
}) {
  final fila = <DesafioBug>[];
  while (fila.length < quantidade) {
    final rodada = [...banco]..shuffle(rnd);
    rodada.sort((a, b) => a.nivel.compareTo(b.nivel));
    fila.addAll(rodada);
  }
  return fila.take(quantidade).toList();
}
