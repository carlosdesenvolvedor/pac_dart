import 'package:equatable/equatable.dart';

import 'habito.dart' show diaDe;

/// Lembrete diário (Fase 1B): a configuração e a REGRA de quando notificar. Dart puro, sem plataforma:
/// quem fala com o sistema é o `AgendadorDeLembrete`. O lembrete é acolhedor, sem culpa — e só vale
/// para o dia em que a meta ainda não foi batida.

/// Quantos dias à frente ficam agendados (cada abertura do app renova).
const diasDeLembrete = 7;

/// Os ids das notificações (um por dia agendado): fixos, para cancelar e reagendar sem sobrar nenhuma.
const idBaseLembrete = 7100;

/// O padrão de fábrica: DESLIGADO, às 20:00.
class ConfigLembrete extends Equatable {
  final bool ligado;
  final int hora, minuto;

  const ConfigLembrete({this.ligado = false, this.hora = 20, this.minuto = 0});

  static const padrao = ConfigLembrete();

  ConfigLembrete copyWith({bool? ligado, int? hora, int? minuto}) =>
      ConfigLembrete(ligado: ligado ?? this.ligado, hora: hora ?? this.hora, minuto: minuto ?? this.minuto);

  /// "20:00".
  String get horario => '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  Map<String, Object> toJson() => {'v': 1, 'ligado': ligado, 'hora': hora, 'minuto': minuto};

  /// Tolerante: dado estragado, de outro tipo ou fora da faixa volta ao padrão (nunca lança).
  static ConfigLembrete fromJson(Object? j) {
    if (j is! Map) return padrao;
    final h = j['hora'], m = j['minuto'];
    return ConfigLembrete(
      ligado: j['ligado'] == true,
      hora: h is int && h >= 0 && h <= 23 ? h : padrao.hora,
      minuto: m is int && m >= 0 && m <= 59 ? m : padrao.minuto,
    );
  }

  @override
  List<Object?> get props => [ligado, hora, minuto];
}

/// Uma notificação a agendar: quando (hora LOCAL do aparelho), o texto e o id.
class LembreteAgendado extends Equatable {
  final int id;
  final DateTime quando;
  final String titulo, corpo;
  const LembreteAgendado({required this.id, required this.quando, required this.titulo, required this.corpo});

  @override
  List<Object?> get props => [id, quando, titulo, corpo];
}

/// Os textos: acolhedores, sem culpa, SEM número de dias (a sequência de amanhã não se sabe hoje) e sem ameaça.
const textosDoLembrete = [
  ('Hora de uma pausa com o inglês 🐦', 'Bastam alguns minutos. O Prof. Dash está esperando você!'),
  ('Um pouquinho de inglês hoje?', 'Alguns exercícios e a sua chama continua acesa 🔥'),
  ('Que tal praticar agora?', 'Cinco minutos já fazem diferença. Seus cartões esperam por você.'),
  ('Seu inglês agradece 🐦', 'Faça a meta de hoje no seu ritmo, sem pressa.'),
];

/// O texto de um dia (gira pelos [textosDoLembrete], o mesmo dia sempre dá o mesmo texto).
(String, String) textoDoLembrete(DateTime dia) => textosDoLembrete[diaDe(dia) % textosDoLembrete.length];

/// Os lembretes a agendar a partir de [agora]: um por dia, nos próximos [dias] dias, no horário escolhido.
/// - desligado ⇒ nenhum;
/// - o horário de hoje que JÁ passou não entra (ligar às 21:00 com horário 20:00 começa amanhã);
/// - com a meta de hoje batida ([metaBatidaHoje]) hoje não entra (só vale para quem ainda não estudou).
/// Cada instante é montado em hora local (o Dart cuida do horário de verão).
List<LembreteAgendado> proximosLembretes({
  required DateTime agora,
  required ConfigLembrete config,
  required bool metaBatidaHoje,
  int dias = diasDeLembrete,
}) {
  if (!config.ligado) return const [];
  final r = <LembreteAgendado>[];
  for (var i = 0; i < dias; i++) {
    if (i == 0 && metaBatidaHoje) continue;
    final quando = DateTime(agora.year, agora.month, agora.day + i, config.hora, config.minuto);
    if (!quando.isAfter(agora)) continue;
    final (titulo, corpo) = textoDoLembrete(quando);
    r.add(LembreteAgendado(id: idBaseLembrete + i, quando: quando, titulo: titulo, corpo: corpo));
  }
  return r;
}
