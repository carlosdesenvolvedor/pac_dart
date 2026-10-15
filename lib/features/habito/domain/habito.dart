import 'package:equatable/equatable.dart';

/// Dia do calendário local como inteiro (dias desde a época): a mesma conta de
/// `Revisao.dia`, sem hora nem fuso — a virada do horário de verão e do ano não
/// muda nada, porque só o ano/mês/dia entram.
int diaDe(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

/// As regras do hábito num lugar só, para ajustar sem caçar número solto.
abstract final class RegrasHabito {
  /// Metas do dia, em exercícios: Leve · Normal · Forte.
  static const leve = 10;
  static const normal = 20;
  static const forte = 40;
  static const metas = [leve, normal, forte];
  static const metaPadrao = normal;

  /// Quantos congelamentos a pessoa guarda no máximo.
  static const maxCongelamentos = 2;

  /// Um congelamento novo a cada tantos dias de sequência.
  static const diasPorCongelamento = 7;

  /// Quantos dias de histórico (feitos e congelados) ficam guardados.
  static const diasGuardados = 60;

  static String nomeDaMeta(int meta) => switch (meta) {
        leve => 'Leve',
        normal => 'Normal',
        forte => 'Forte',
        _ => 'Meta',
      };
}

/// O hábito de estudar da pessoa: sequência de dias, meta do dia e congelamentos.
/// Imutável e sem Flutter — toda regra está aqui e é função pura do "agora".
///
/// Vale para a conta inteira (Dart, C# e Inglês somam na mesma sequência). O dia
/// só conta quando a pessoa bate a meta de exercícios.
class Habito extends Equatable {
  /// Exercícios por dia (um de [RegrasHabito.metas]).
  final int meta;

  /// O "hoje" a que [unidadesHoje] se refere (dia inteiro, ver [diaDe]).
  final int dia;

  /// Exercícios feitos em [dia].
  final int unidadesHoje;

  /// Sequência na última meta batida.
  final int sequencia;

  /// Maior sequência já alcançada.
  final int melhor;

  /// Dia em que a meta foi batida pela última vez (null = nunca).
  final int? ultimoDiaMeta;

  /// Congelamentos guardados (0..[RegrasHabito.maxCongelamentos]).
  final int congelamentos;

  /// Dias em que a meta foi batida (só os últimos [RegrasHabito.diasGuardados]).
  final List<int> historico;

  /// Dias cobertos por um congelamento (idem).
  final List<int> congelados;

  const Habito({
    this.meta = RegrasHabito.metaPadrao,
    this.dia = 0,
    this.unidadesHoje = 0,
    this.sequencia = 0,
    this.melhor = 0,
    this.ultimoDiaMeta,
    this.congelamentos = 0,
    this.historico = const [],
    this.congelados = const [],
  });

  /// Quem nunca estudou (ou um documento sem hábito).
  static const vazio = Habito();

  Habito copyWith({
    int? meta,
    int? dia,
    int? unidadesHoje,
    int? sequencia,
    int? melhor,
    int? ultimoDiaMeta,
    int? congelamentos,
    List<int>? historico,
    List<int>? congelados,
  }) =>
      Habito(
        meta: meta ?? this.meta,
        dia: dia ?? this.dia,
        unidadesHoje: unidadesHoje ?? this.unidadesHoje,
        sequencia: sequencia ?? this.sequencia,
        melhor: melhor ?? this.melhor,
        ultimoDiaMeta: ultimoDiaMeta ?? this.ultimoDiaMeta,
        congelamentos: congelamentos ?? this.congelamentos,
        historico: historico ?? this.historico,
        congelados: congelados ?? this.congelados,
      );

  /// O "hoje" que vale para as contas: o relógio que volta atrás é ignorado
  /// (nunca fica antes do dia já registrado nem da última meta).
  int _hoje(DateTime agora) {
    var d = diaDe(agora);
    if (d < dia) d = dia;
    final u = ultimoDiaMeta;
    if (u != null && d < u) d = u;
    return d;
  }

  /// O dia que vale como "hoje" para este hábito (relógio que volta atrás é ignorado).
  int hoje(DateTime agora) => _hoje(agora);

  /// Soma [unidades] exercícios feitos em [agora]. Vira o dia sozinho e, ao
  /// alcançar a meta pela 1ª vez no dia, atualiza sequência, melhor e congelamentos.
  Habito registrar(int unidades, DateTime agora) {
    if (unidades < 1) return this;
    return _aplicar(unidades, agora, meta);
  }

  /// Troca a meta (só 10/20/40). Se o que já foi feito hoje alcança a nova, a
  /// meta de hoje conta como batida.
  Habito mudarMeta(int novaMeta, DateTime agora) {
    if (!RegrasHabito.metas.contains(novaMeta)) return this;
    return _aplicar(0, agora, novaMeta);
  }

  Habito _aplicar(int unidades, DateTime agora, int novaMeta) {
    final d = _hoje(agora);
    final feitas = (d > dia ? 0 : unidadesHoje) + unidades;
    final base = copyWith(meta: novaMeta, dia: d, unidadesHoje: feitas);
    if (feitas < novaMeta || ultimoDiaMeta == d) return base;

    // meta batida hoje
    final u = ultimoDiaMeta;
    final perdidos = u == null ? 0 : d - u - 1;
    var seq = sequencia;
    var frz = congelamentos;
    var gelados = congelados;
    if (u == null) {
      seq = 1;
    } else if (perdidos == 0) {
      seq += 1;
    } else if (perdidos <= frz) {
      frz -= perdidos;
      gelados = [...gelados, for (var x = u + 1; x < d; x++) x];
      seq += 1;
    } else {
      // recomeça: os congelamentos guardados NÃO são gastos
      seq = 1;
    }
    if (seq > sequencia && seq % RegrasHabito.diasPorCongelamento == 0) {
      frz = frz + 1 > RegrasHabito.maxCongelamentos ? RegrasHabito.maxCongelamentos : frz + 1;
    }
    return base.copyWith(
      sequencia: seq,
      melhor: seq > melhor ? seq : melhor,
      ultimoDiaMeta: d,
      congelamentos: frz,
      historico: _aparar([...historico, d]),
      congelados: _aparar(gelados),
    );
  }

  /// Ordenada, sem repetidos e só com os últimos [RegrasHabito.diasGuardados] dias.
  static List<int> _aparar(Iterable<int> dias) {
    final l = dias.toSet().toList()..sort();
    return l.length > RegrasHabito.diasGuardados ? l.sublist(l.length - RegrasHabito.diasGuardados) : l;
  }

  /// A sequência que o chip mostra ANTES de estudar hoje: ainda viva (a meta de
  /// hoje ou de um dia que um congelamento cobre) ou 0 — nunca um número velho.
  int sequenciaVisivel(DateTime agora) {
    final u = ultimoDiaMeta;
    if (u == null) return 0;
    final d = _hoje(agora);
    if (u == d) return sequencia;
    return d - u - 1 <= congelamentos ? sequencia : 0;
  }

  /// A meta de hoje já foi batida?
  bool bateuHoje(DateTime agora) => ultimoDiaMeta != null && ultimoDiaMeta == _hoje(agora);

  /// Sequência viva e hoje ainda sem meta: é o momento de estudar.
  bool emRisco(DateTime agora) => sequenciaVisivel(agora) > 0 && !bateuHoje(agora);

  /// Quanto da meta de hoje já foi feito (0..1). Dia virou e nada feito ainda = 0.
  double progressoHoje(DateTime agora) {
    if (dia != _hoje(agora) || meta <= 0) return 0;
    final p = unidadesHoje / meta;
    return p > 1 ? 1 : p;
  }

  /// Exercícios feitos hoje (0 se o dia já virou).
  int feitasHoje(DateTime agora) => dia == _hoje(agora) ? unidadesHoje : 0;

  /// O que aconteceu em [dia]: feito, congelado ou perdido.
  EstadoDoDia estadoDe(int d) => historico.contains(d)
      ? EstadoDoDia.feito
      : congelados.contains(d)
          ? EstadoDoDia.congelado
          : EstadoDoDia.perdido;

  /// Junta o hábito deste aparelho com o da nuvem (cada um pode estar adiantado):
  /// vence quem bateu a meta mais recentemente (empate: o dia, depois os exercícios
  /// feitos); o melhor é o maior dos dois e os históricos se unem. Comutativa e
  /// idempotente.
  static Habito mesclar(Habito a, Habito b) {
    final v = _ordem(a, b) >= 0 ? a : b;
    return v.copyWith(
      melhor: [a.melhor, b.melhor, v.sequencia].reduce((x, y) => x > y ? x : y),
      historico: _aparar([...a.historico, ...b.historico]),
      congelados: _aparar([...a.congelados, ...b.congelados]),
    );
  }

  /// Ordem total (a 1ª pessoa "mais adiantada" é a maior); os últimos critérios
  /// só existem para o desempate não depender de quem vem primeiro.
  static int _ordem(Habito a, Habito b) {
    final ua = a.ultimoDiaMeta, ub = b.ultimoDiaMeta;
    if (ua != ub) {
      if (ua == null) return -1;
      if (ub == null) return 1;
      return ua.compareTo(ub);
    }
    for (final c in [
      a.dia.compareTo(b.dia),
      a.unidadesHoje.compareTo(b.unidadesHoje),
      a.sequencia.compareTo(b.sequencia),
      a.congelamentos.compareTo(b.congelamentos),
      a.meta.compareTo(b.meta),
    ]) {
      if (c != 0) return c;
    }
    return 0;
  }

  /// `{v, meta, dia, un, seq, melhor, ult, frz, hist, gel}` — o mesmo formato no
  /// aparelho e no Firestore.
  Map<String, Object?> toJson() => {
        'v': 1,
        'meta': meta,
        'dia': dia,
        'un': unidadesHoje,
        'seq': sequencia,
        'melhor': melhor,
        'ult': ultimoDiaMeta,
        'frz': congelamentos,
        'hist': historico,
        'gel': congelados,
      };

  /// Lê o que foi gravado. Nunca lança: campo ausente, de tipo errado ou fora do
  /// possível volta ao padrão (documento antigo, editado à mão ou corrompido).
  factory Habito.fromJson(Object? bruto) {
    if (bruto is! Map) return vazio;
    int? inteiro(String k) {
      final v = bruto[k];
      return v is num && v.isFinite ? v.toInt() : null;
    }

    int naoNegativo(String k) {
      final v = inteiro(k);
      return v == null || v < 0 ? 0 : v;
    }

    List<int> dias(String k) {
      final v = bruto[k];
      return v is List ? _aparar([for (final e in v) if (e is num && e.isFinite && e >= 0) e.toInt()]) : const [];
    }

    final meta = inteiro('meta');
    final ult = inteiro('ult');
    final seq = naoNegativo('seq');
    final frz = naoNegativo('frz');
    final dia = naoNegativo('dia');
    return Habito(
      meta: meta != null && RegrasHabito.metas.contains(meta) ? meta : RegrasHabito.metaPadrao,
      // `dia` nunca fica antes da última meta (senão as contas de dias perdidos dariam negativo)
      dia: ult != null && ult > dia ? ult : dia,
      unidadesHoje: naoNegativo('un'),
      sequencia: seq,
      melhor: naoNegativo('melhor') < seq ? seq : naoNegativo('melhor'),
      ultimoDiaMeta: ult != null && ult >= 0 ? ult : null,
      congelamentos: frz > RegrasHabito.maxCongelamentos ? RegrasHabito.maxCongelamentos : frz,
      historico: dias('hist'),
      congelados: dias('gel'),
    );
  }

  @override
  List<Object?> get props =>
      [meta, dia, unidadesHoje, sequencia, melhor, ultimoDiaMeta, congelamentos, historico, congelados];
}

enum EstadoDoDia { feito, congelado, perdido }
