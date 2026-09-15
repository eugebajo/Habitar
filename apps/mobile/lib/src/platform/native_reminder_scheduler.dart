import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NativeReminderScheduler implements LocalReminderScheduler {
  NativeReminderScheduler._(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  static Future<NativeReminderScheduler> create() async {
    timezone_data.initializeTimeZones();
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    // Etapa 3: el permiso de notificaciones (POST_NOTIFICATIONS en
    // Android, el mismo permiso del sistema operativo que gobierna tanto
    // estos recordatorios locales como los avisos push - no son dos
    // permisos distintos) ya NO se pide aca, en cada arranque de la app.
    // Pedirlo antes de que el adulto entienda para que baja mucho la
    // aceptacion - ver push_notifications.dart, que lo pide en el
    // momento adecuado (primera vez que se entra a Familia o se crea una
    // rutina), con una explicacion breve antes del dialogo del sistema.
    // initialize() de arriba sigue funcionando sin el permiso concedido -
    // programar una notificacion nunca falla por esto, solo no se
    // muestra hasta que el permiso este otorgado.
    return NativeReminderScheduler._(notifications);
  }

  @override
  Future<void> cancel(String id) {
    return _notifications.cancel(_notificationId(id));
  }

  @override
  Future<void> schedule(LocalReminderRequest request) async {
    final scheduledAt = request.scheduledAt;
    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }
    await _notifications.zonedSchedule(
      _notificationId(request.id),
      request.title,
      request.body,
      timezone.TZDateTime.from(scheduledAt, timezone.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          request.channelId,
          'Recordatorios de rutinas',
          channelDescription:
              'Avisos locales para rutinas familiares de Habitar.',
          importance:
              request.sound ? Importance.high : Importance.defaultImportance,
          priority: request.sound ? Priority.high : Priority.defaultPriority,
          enableVibration: request.vibration,
          playSound: request.sound,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: request.sound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> showNow({
    required String id,
    required String title,
    required String body,
    String channelId = 'routine_reminders',
  }) async {
    await _notifications.show(
      _notificationId(id),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'push_notifications',
          'Avisos de la familia',
          channelDescription:
              'Avisos push reenviados como notificacion local mientras la app esta abierta.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}

int _notificationId(String id) {
  var hash = 0;
  for (final codeUnit in id.codeUnits) {
    hash = 0x1fffffff & (hash + codeUnit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash;
}
