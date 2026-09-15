// Etapa 3 (notificaciones push), Parte 4: registro/rotación/borrado de
// token contra un PushMessagingGateway falso (nunca toca Firebase de
// verdad), y el diálogo de permiso mostrándose una sola vez.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_mobile/src/platform/push_messaging_gateway.dart';
import 'package:habitar_mobile/src/push_notifications.dart';
import 'package:habitar_notifications/notifications.dart' as notifications;

void main() {
  group('PushNotificationService.registerCurrentDevice', () {
    test('guarda el token con el usuario y la plataforma correctos',
        () async {
      final gateway = _FakePushMessagingGateway()..tokenToReturn = 'token-1';
      final deviceTokens = InMemoryDeviceTokenRepository();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: deviceTokens,
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );

      await service.registerCurrentDevice('user-1');

      final tokens = deviceTokens.tokensForUser('user-1');
      expect(tokens, hasLength(1));
      expect(tokens.single.token, 'token-1');
    });

    test('token null (permiso sin resolver todavía) no guarda nada',
        () async {
      final gateway = _FakePushMessagingGateway()..tokenToReturn = null;
      final deviceTokens = InMemoryDeviceTokenRepository();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: deviceTokens,
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );

      await service.registerCurrentDevice('user-1');

      expect(deviceTokens.tokensForUser('user-1'), isEmpty);
    });

    test('un fallo del repositorio nunca se propaga (best-effort)', () async {
      final gateway = _FakePushMessagingGateway()..tokenToReturn = 'token-1';
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: _ThrowingDeviceTokenRepository(),
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );

      // No debe lanzar - si esto tira, el test falla solo.
      await service.registerCurrentDevice('user-1');
    });

    test('la rotación de FCM actualiza el token guardado', () async {
      final gateway = _FakePushMessagingGateway()..tokenToReturn = 'token-1';
      final deviceTokens = InMemoryDeviceTokenRepository();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: deviceTokens,
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );

      await service.registerCurrentDevice('user-1');
      gateway.emitTokenRefresh('token-2');
      // El listener de onTokenRefresh es async - darle una vuelta al
      // event loop para que corra antes de leer el resultado.
      await Future<void>.delayed(Duration.zero);

      final tokens = deviceTokens.tokensForUser('user-1');
      expect(tokens.map((t) => t.token), containsAll(['token-1', 'token-2']));
    });
  });

  group('PushNotificationService.unregisterCurrentDevice', () {
    test('borra el token de este dispositivo y lo invalida en el gateway',
        () async {
      final gateway = _FakePushMessagingGateway()..tokenToReturn = 'token-1';
      final deviceTokens = InMemoryDeviceTokenRepository();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: deviceTokens,
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );
      await service.registerCurrentDevice('user-1');

      await service.unregisterCurrentDevice();

      expect(deviceTokens.tokensForUser('user-1'), isEmpty);
      expect(gateway.deleteTokenCalled, isTrue);
    });

    test('sin login previo, no hace nada (no hay token que borrar)',
        () async {
      final gateway = _FakePushMessagingGateway();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: InMemoryDeviceTokenRepository(),
        reminderScheduler: notifications.InMemoryReminderScheduler(),
      );

      await service.unregisterCurrentDevice();

      expect(gateway.deleteTokenCalled, isFalse);
    });
  });

  group('PushNotificationService.requestPermissionIfNeeded', () {
    testWidgets('muestra el diálogo y llama a requestPermission la primera vez',
        (tester) async {
      final gateway = _FakePushMessagingGateway();
      final localStore = _InMemoryLocalStore();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: InMemoryDeviceTokenRepository(),
        reminderScheduler: notifications.InMemoryReminderScheduler(),
        localStore: localStore,
      );

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => service.requestPermissionIfNeeded(context),
            child: const Text('pedir'),
          ),
        ),
      ));
      await tester.tap(find.text('pedir'));
      await tester.pumpAndSettle();

      expect(find.text('Avisos para toda la familia'), findsOneWidget);
      await tester.tap(find.text('Activar avisos'));
      await tester.pumpAndSettle();

      expect(gateway.requestPermissionCalls, 1);
    });

    testWidgets('no vuelve a mostrarse una segunda vez', (tester) async {
      final gateway = _FakePushMessagingGateway();
      final localStore = _InMemoryLocalStore();
      final service = PushNotificationService(
        gateway: gateway,
        deviceTokenRepository: InMemoryDeviceTokenRepository(),
        reminderScheduler: notifications.InMemoryReminderScheduler(),
        localStore: localStore,
      );

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => service.requestPermissionIfNeeded(context),
            child: const Text('pedir'),
          ),
        ),
      ));

      // Primera vez: aparece y se descarta con "Ahora no" (nunca se pide
      // el permiso del sistema si el adulto elige eso).
      await tester.tap(find.text('pedir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(gateway.requestPermissionCalls, 0);

      // Segunda vez: ni el diálogo ni el permiso del sistema, sin importar
      // qué se eligió la primera vez - ya se preguntó en este dispositivo.
      await tester.tap(find.text('pedir'));
      await tester.pumpAndSettle();

      expect(find.text('Avisos para toda la familia'), findsNothing);
      expect(gateway.requestPermissionCalls, 0);
    });
  });
}

class _FakePushMessagingGateway implements PushMessagingGateway {
  String? tokenToReturn = 'fake-token';
  int requestPermissionCalls = 0;
  bool deleteTokenCalled = false;
  RemoteMessageData? initialMessage;

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _onMessageController = StreamController<RemoteMessageData>.broadcast();
  final _onMessageOpenedAppController =
      StreamController<RemoteMessageData>.broadcast();

  @override
  Future<String?> getToken() async => tokenToReturn;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  void emitTokenRefresh(String token) => _tokenRefreshController.add(token);

  @override
  Future<PushPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return PushPermissionStatus.granted;
  }

  @override
  Stream<RemoteMessageData> get onMessage => _onMessageController.stream;

  @override
  Stream<RemoteMessageData> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Future<RemoteMessageData?> getInitialMessage() async => initialMessage;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalled = true;
  }
}

class _ThrowingDeviceTokenRepository implements DeviceTokenRepository {
  @override
  Future<void> registerToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    throw StateError('sin red, a propósito para este test');
  }

  @override
  Future<void> deleteToken(String token) async {
    throw StateError('sin red, a propósito para este test');
  }
}

class _InMemoryLocalStore implements LocalStore {
  final Map<String, Map<String, Map<String, Object?>>> _data = {};

  @override
  Future<void> put(
      String collection, String id, Map<String, Object?> value) async {
    (_data[collection] ??= {})[id] = value;
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async =>
      _data[collection]?[id];

  @override
  Future<List<Map<String, Object?>>> list(String collection) async =>
      _data[collection]?.values.toList(growable: false) ?? const [];

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
  }
}
