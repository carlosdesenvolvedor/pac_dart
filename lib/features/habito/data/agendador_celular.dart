import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/lembrete.dart';
import 'agendador_lembrete.dart';

/// O lembrete no Android e no iOS, pelo plugin `flutter_local_notifications`.
///
/// Cada lembrete é uma notificação ÚNICA num instante absoluto (a hora local do aparelho, já convertida):
/// por isso não precisa saber o NOME do fuso (o `TZDateTime` vai em UTC) e o horário de verão já vem certo.
/// Alarme NÃO exato (`inexactAllowWhileIdle`): um lembrete de estudo não precisa de minuto exato, e assim
/// o app não pede a permissão de alarmes exatos (que a Play restringe).
class AgendadorDoCelular implements AgendadorDeLembrete {
  static const _canalId = 'lembrete_diario';
  static const _canalNome = 'Lembrete diário';
  static const _canalDescricao = 'Um lembrete por dia para você estudar inglês';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _iniciando;

  AgendadorDoCelular({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static bool get _ehCelular =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool get disponivel => _ehCelular;

  /// Inicializa o plugin uma vez. As permissões NÃO são pedidas aqui (só quando a pessoa liga o lembrete).
  Future<void> _iniciar() => _iniciando ??= _plugin
          .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      )
          .then<void>((_) {}, onError: (Object _) {
        _iniciando = null; // tenta de novo na próxima vez
      });

  @override
  Future<bool> pedirPermissao() async {
    if (!disponivel) return false;
    try {
      await _iniciar();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await a?.requestNotificationsPermission() ?? false;
      }
      final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> substituir(List<LembreteAgendado> lembretes) async {
    if (!disponivel) return;
    try {
      await _iniciar();
      await _cancelarOsNossos();
      for (final l in lembretes) {
        await _plugin.zonedSchedule(
          id: l.id,
          scheduledDate: tz.TZDateTime.from(l.quando, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(_canalId, _canalNome, channelDescription: _canalDescricao),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: l.titulo,
          body: l.corpo,
        );
      }
    } catch (_) {
      // sem permissão ou sem suporte: o estudo segue, só não há lembrete
    }
  }

  @override
  Future<void> cancelarTodos() async {
    if (!disponivel) return;
    try {
      await _iniciar();
      await _cancelarOsNossos();
    } catch (_) {}
  }

  Future<void> _cancelarOsNossos() async {
    for (var i = 0; i < diasDeLembrete; i++) {
      await _plugin.cancel(id: idBaseLembrete + i);
    }
  }
}
