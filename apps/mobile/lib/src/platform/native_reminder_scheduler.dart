import 'dart:io';

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
    if (Platform.isAndroid) {
      await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
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
