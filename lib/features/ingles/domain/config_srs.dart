import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Os ajustes da revisão estilo Anki (os "Options" do baralho): quantas
/// revisões por dia, quantos cartões inglês → português NOVOS por dia, quanto da
/// memória o agendador tenta manter e quais baralhos têm o sentido invertido.
class ConfigSrs extends Equatable {
  static const opcoesLimite = [20, 50, 80, 150, 300];
  static const opcoesNovos = [0, 5, 10, 20, 40];

  /// 90% é o padrão do Anki; acima de ~95% a carga explode (manual do Anki).
  static const opcoesRetencao = [0.85, 0.90, 0.95];

  /// Revisões por dia (o resto fica para amanhã).
  final int limiteRevisoes;

  /// Cartões inglês → português que entram por dia (os "novos" do Anki).
  final int novosPorDia;

  /// Chance de lembrar que o FSRS tenta manter (0,7 a 0,97).
  final double retencao;

  /// Baralhos (`Trilha.baralhoId`) que também são estudados de inglês para português.
  final Set<String> reversos;

  const ConfigSrs({this.limiteRevisoes = 80, this.novosPorDia = 10, this.retencao = 0.90, this.reversos = const {}});

  static const padrao = ConfigSrs();

  bool reversoLigado(String baralho) => reversos.contains(baralho);

  ConfigSrs copyWith({int? limiteRevisoes, int? novosPorDia, double? retencao, Set<String>? reversos}) => ConfigSrs(
        limiteRevisoes: limiteRevisoes ?? this.limiteRevisoes,
        novosPorDia: novosPorDia ?? this.novosPorDia,
        retencao: retencao ?? this.retencao,
        reversos: reversos ?? this.reversos,
      );

  /// Liga ou desliga o sentido invertido de vários baralhos de uma vez.
  ConfigSrs comReversos(Iterable<String> baralhos, {required bool ligar}) =>
      copyWith(reversos: ligar ? {...reversos, ...baralhos} : reversos.difference(baralhos.toSet()));

  String codificar() => jsonEncode({
        'limite': limiteRevisoes,
        'novos': novosPorDia,
        'retencao': retencao,
        'reversos': reversos.toList()..sort(),
      });

  /// Nunca lança: o que faltar ou vier estranho cai no padrão.
  static ConfigSrs decodificar(Object? bruto) {
    try {
      final j = jsonDecode('$bruto');
      if (j is! Map) return padrao;
      int inteiro(Object? v, int padrao, int min, int max) => v is num ? v.toInt().clamp(min, max) : padrao;
      final ret = j['retencao'];
      return ConfigSrs(
        limiteRevisoes: inteiro(j['limite'], padrao.limiteRevisoes, 1, 2000),
        novosPorDia: inteiro(j['novos'], padrao.novosPorDia, 0, 500),
        retencao: ret is num && ret.isFinite ? ret.toDouble().clamp(0.7, 0.97) : padrao.retencao,
        reversos: {for (final r in (j['reversos'] is List ? j['reversos'] as List : const [])) if (r is String && r.isNotEmpty) r},
      );
    } catch (_) {
      return padrao;
    }
  }

  @override
  List<Object?> get props => [limiteRevisoes, novosPorDia, retencao, reversos];
}
