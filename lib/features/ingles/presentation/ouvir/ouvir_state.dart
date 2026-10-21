import 'package:equatable/equatable.dart';

import '../../domain/config_ouvir.dart';
import '../../domain/fila_ouvir.dart';

enum StatusOuvir { parado, tocando, pausado, acabou }

enum MotivoPausa { usuario, outraFala, semSom, timer }

/// De onde vem a fila: `curso` | `setlist:<id>` | `avulso`.
class FonteOuvir extends Equatable {
  final String id;
  final String titulo;

  const FonteOuvir(this.id, this.titulo);

  @override
  List<Object?> get props => [id, titulo];
}

class OuvirState extends Equatable {
  final StatusOuvir status;
  final MotivoPausa? motivo;
  final FonteOuvir? fonte;
  final List<Faixa> fila;
  final int indice;
  final FaseOuvir fase;

  /// A passada atual da frase ([vez] de [de]).
  final int vez, de;
  final ConfigOuvir config;
  final DesligarEm desligar;
  final DateTime? desligaAs;

  /// O "Tocando agora" está aberto (o mini-player some).
  final bool telaCheia;

  /// Frases ouvidas nesta sessão.
  final int ouvidas;

  const OuvirState({
    this.status = StatusOuvir.parado,
    this.motivo,
    this.fonte,
    this.fila = const [],
    this.indice = 0,
    this.fase = FaseOuvir.ouvindo,
    this.vez = 1,
    this.de = 1,
    this.config = const ConfigOuvir(),
    this.desligar = DesligarEm.nunca,
    this.desligaAs,
    this.telaCheia = false,
    this.ouvidas = 0,
  });

  /// [semMotivo]/[semFonte]/[semDesligaAs] zeram os campos que aceitam nulo.
  OuvirState copyWith({
    StatusOuvir? status,
    MotivoPausa? motivo,
    bool semMotivo = false,
    FonteOuvir? fonte,
    bool semFonte = false,
    List<Faixa>? fila,
    int? indice,
    FaseOuvir? fase,
    int? vez,
    int? de,
    ConfigOuvir? config,
    DesligarEm? desligar,
    DateTime? desligaAs,
    bool semDesligaAs = false,
    bool? telaCheia,
    int? ouvidas,
  }) =>
      OuvirState(
        status: status ?? this.status,
        motivo: semMotivo ? null : (motivo ?? this.motivo),
        fonte: semFonte ? null : (fonte ?? this.fonte),
        fila: fila ?? this.fila,
        indice: indice ?? this.indice,
        fase: fase ?? this.fase,
        vez: vez ?? this.vez,
        de: de ?? this.de,
        config: config ?? this.config,
        desligar: desligar ?? this.desligar,
        desligaAs: semDesligaAs ? null : (desligaAs ?? this.desligaAs),
        telaCheia: telaCheia ?? this.telaCheia,
        ouvidas: ouvidas ?? this.ouvidas,
      );

  /// A faixa tocando agora (null sem fila).
  Faixa? get atual => indice >= 0 && indice < fila.length ? fila[indice] : null;

  /// Segundos de fala que faltam (da faixa atual ao fim), na velocidade e repetições da config — sem as
  /// pausas; estimativa para "faltam ~18 min".
  double get restanteSeg {
    var s = 0.0;
    for (var i = indice < 0 ? 0 : indice; i < fila.length; i++) {
      s += fila[i].segundos;
    }
    return s * config.repeticoes / config.velocidade;
  }

  bool get ativo => status != StatusOuvir.parado;

  @override
  List<Object?> get props =>
      [status, motivo, fonte, fila, indice, fase, vez, de, config, desligar, desligaAs, telaCheia, ouvidas];
}
