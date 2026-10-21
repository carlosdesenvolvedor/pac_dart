import 'package:equatable/equatable.dart';

import 'fila_ouvir.dart';

enum ModoOuvir { soIngles, inglesPortugues, portuguesIngles }

enum PausaOuvir { curta, media, longa, eco }

enum DesligarEm { nunca, min15, min30, min60, fimDaLicao }

enum FaseOuvir { ouvindo, traducao, pense, suaVez, respiro }

/// Como o "🎧 Ouvir" toca (pref `en_ouvir_cfg`).
class ConfigOuvir extends Equatable {
  /// As velocidades que os chips oferecem.
  static const velocidades = [0.75, 0.9, 1.0, 1.15];

  final ModoOuvir modo;

  /// Uma de [velocidades].
  final double velocidade;

  /// 1..3.
  final int repeticoes;

  /// Da 2ª passada em diante, toca a 0,8 × [velocidade].
  final bool segundaDevagar;
  final PausaOuvir pausa;
  final bool mostrarTraducao;

  /// A foto da cena e o emoji do sentido da frase no player e no "Tocando agora".
  final bool mostrarImagens;
  final bool repetirTudo;

  const ConfigOuvir({
    this.modo = ModoOuvir.soIngles,
    this.velocidade = 1.0,
    this.repeticoes = 1,
    this.segundaDevagar = false,
    this.pausa = PausaOuvir.media,
    this.mostrarTraducao = true,
    this.mostrarImagens = true,
    this.repetirTudo = false,
  });

  ConfigOuvir copyWith({
    ModoOuvir? modo,
    double? velocidade,
    int? repeticoes,
    bool? segundaDevagar,
    PausaOuvir? pausa,
    bool? mostrarTraducao,
    bool? mostrarImagens,
    bool? repetirTudo,
  }) =>
      ConfigOuvir(
        modo: modo ?? this.modo,
        velocidade: velocidade ?? this.velocidade,
        repeticoes: repeticoes ?? this.repeticoes,
        segundaDevagar: segundaDevagar ?? this.segundaDevagar,
        pausa: pausa ?? this.pausa,
        mostrarTraducao: mostrarTraducao ?? this.mostrarTraducao,
        mostrarImagens: mostrarImagens ?? this.mostrarImagens,
        repetirTudo: repetirTudo ?? this.repetirTudo,
      );

  /// Chaves curtas: `mo` modo, `v` velocidade, `r` repetições, `d` 2ª devagar, `pa` pausa, `t` tradução,
  /// `im` imagens, `rt` repetir tudo.
  Map<String, dynamic> toJson() => {
        'mo': modo.name,
        'v': velocidade,
        'r': repeticoes,
        'd': segundaDevagar,
        'pa': pausa.name,
        't': mostrarTraducao,
        'im': mostrarImagens,
        'rt': repetirTudo,
      };

  /// Tolerante: dado estragado/ausente → o padrão (campo a campo).
  static ConfigOuvir fromJson(Map? j) {
    if (j == null) return const ConfigOuvir();
    const p = ConfigOuvir();
    T? enumDe<T extends Enum>(List<T> valores, Object? nome) {
      for (final v in valores) {
        if (v.name == nome) return v;
      }
      return null;
    }

    bool boolDe(Object? x, bool padrao) => x is bool ? x : padrao;
    final v = j['v'];
    final r = j['r'];
    return ConfigOuvir(
      modo: enumDe(ModoOuvir.values, j['mo']) ?? p.modo,
      velocidade: v is num && v.isFinite ? velocidadeMaisPerto(v.toDouble()) : p.velocidade,
      repeticoes: r is num && r.isFinite ? r.round().clamp(1, 3) : p.repeticoes,
      segundaDevagar: boolDe(j['d'], p.segundaDevagar),
      pausa: enumDe(PausaOuvir.values, j['pa']) ?? p.pausa,
      mostrarTraducao: boolDe(j['t'], p.mostrarTraducao),
      mostrarImagens: boolDe(j['im'], p.mostrarImagens),
      repetirTudo: boolDe(j['rt'], p.repetirTudo),
    );
  }

  /// A de [velocidades] mais perto de [v].
  static double velocidadeMaisPerto(double v) {
    var melhor = velocidades.first;
    for (final x in velocidades) {
      if ((x - v).abs() < (melhor - v).abs()) melhor = x;
    }
    return melhor;
  }

  @override
  List<Object?> get props => [modo, velocidade, repeticoes, segundaDevagar, pausa, mostrarTraducao, mostrarImagens, repetirTudo];
}

/// Um passo do roteiro de uma faixa.
sealed class PassoOuvir extends Equatable {
  const PassoOuvir();
}

/// Fala o inglês (passada [vez] de [de]) a [fator] da velocidade gravada.
class FalaEn extends PassoOuvir {
  final double fator;
  final int vez, de;

  const FalaEn({required this.fator, this.vez = 1, this.de = 1});

  @override
  List<Object?> get props => [fator, vez, de];
}

/// Fala a tradução (voz pt-BR do sistema).
class FalaPt extends PassoOuvir {
  const FalaPt();

  @override
  List<Object?> get props => const [];
}

/// Silêncio de [d] (a tela mostra [fase]).
class Silencio extends PassoOuvir {
  final Duration d;
  final FaseOuvir fase;

  const Silencio({required this.d, required this.fase});

  @override
  List<Object?> get props => [d, fase];
}

/// O respiro entre o inglês e a tradução no modo "Inglês → português".
const pausaAntesDaTraducao = Duration(milliseconds: 400);

/// O que o fim de uma lição soma à última pausa.
const extraFimDeLicao = Duration(milliseconds: 1500);

/// Da 2ª passada em diante (com "2ª vez devagar").
const fatorDevagar = .8;

Duration _seg(double s) => Duration(milliseconds: (s * 1000).round());

/// A pausa depois da fala: curta 0,5 s; média 1 s; longa 2 s; eco = o tempo de repetir em voz alta,
/// `clamp(seg × 1,2 / v + 0,8, 1,5, 9)`.
Duration pausaPara(PausaOuvir p, double segundos, double velocidade) {
  final v = velocidade > 0 ? velocidade : 1.0;
  return switch (p) {
    PausaOuvir.curta => const Duration(milliseconds: 500),
    PausaOuvir.media => const Duration(seconds: 1),
    PausaOuvir.longa => const Duration(seconds: 2),
    PausaOuvir.eco => _seg((segundos * 1.2 / v + .8).clamp(1.5, 9.0)),
  };
}

/// O "🧠 Pense" do modo "Português → inglês": `clamp(seg × 1,5 / v + 1, 2, 10)`.
Duration pausaPense(double segundos, double velocidade) {
  final v = velocidade > 0 ? velocidade : 1.0;
  return _seg((segundos * 1.5 / v + 1.0).clamp(2.0, 10.0));
}

/// O roteiro de uma faixa:
/// - Só inglês: `[FalaEn, pausa] × repetições`;
/// - Inglês → português: `[FalaEn, pausa] × (repetições − 1), FalaEn, 0,4 s, FalaPt, pausa`;
/// - Português → inglês: `FalaPt, pense, [FalaEn, pausa] × repetições`.
///
/// Com "2ª vez devagar", da 2ª passada em diante a fala vai a 0,8 × velocidade. A pausa do eco mostra
/// "🗣️ Sua vez" ([FaseOuvir.suaVez]); as outras, [FaseOuvir.respiro]. [fimDeLicao] soma 1,5 s à última.
/// Sem tradução ([Faixa.pt] vazio), os modos com português viram "Só inglês".
List<PassoOuvir> passosDa(Faixa f, ConfigOuvir c, {required bool fimDeLicao}) {
  final v = c.velocidade > 0 ? c.velocidade : 1.0;
  final rep = c.repeticoes.clamp(1, 3);
  final gap = pausaPara(c.pausa, f.segundos, v);
  final faseGap = c.pausa == PausaOuvir.eco ? FaseOuvir.suaVez : FaseOuvir.respiro;
  FalaEn en(int vez) => FalaEn(fator: vez >= 2 && c.segundaDevagar ? v * fatorDevagar : v, vez: vez, de: rep);
  Silencio pausa() => Silencio(d: gap, fase: faseGap);
  final modo = f.pt.trim().isEmpty ? ModoOuvir.soIngles : c.modo;
  final passos = <PassoOuvir>[];
  switch (modo) {
    case ModoOuvir.soIngles:
      for (var vez = 1; vez <= rep; vez++) {
        passos.addAll([en(vez), pausa()]);
      }
    case ModoOuvir.inglesPortugues:
      for (var vez = 1; vez < rep; vez++) {
        passos.addAll([en(vez), pausa()]);
      }
      passos.addAll([
        en(rep),
        const Silencio(d: pausaAntesDaTraducao, fase: FaseOuvir.traducao),
        const FalaPt(),
        pausa(),
      ]);
    case ModoOuvir.portuguesIngles:
      passos.addAll([const FalaPt(), Silencio(d: pausaPense(f.segundos, v), fase: FaseOuvir.pense)]);
      for (var vez = 1; vez <= rep; vez++) {
        passos.addAll([en(vez), pausa()]);
      }
  }
  if (fimDeLicao) {
    final ultima = passos.last as Silencio;
    passos[passos.length - 1] = Silencio(d: ultima.d + extraFimDeLicao, fase: ultima.fase);
  }
  return passos;
}
