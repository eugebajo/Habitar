// Etapa 3 (notificaciones push). Envuelve firebase_messaging detras de una
// interfaz propia - mismo patron que FlutterSupabaseAuthGateway en este
// mismo directorio: el resto de la app (y sobre todo los tests) nunca
// dependen del plugin real, solo de esta interfaz chica, sustituible por
// un doble en memoria.

import 'package:firebase_messaging/firebase_messaging.dart' as fm;

/// Estado del permiso de notificaciones del sistema operativo. Un
/// subconjunto deliberadamente chico de fm.AuthorizationStatus - authorized
/// y provisional (iOS) cuentan como "concedido" para el resto de la app,
/// que solo necesita saber si puede esperar que un push se muestre o no.
enum PushPermissionStatus { granted, denied, notDetermined }

/// Una notificacion recibida, ya desarmada del tipo fm.RemoteMessage real -
/// asi ningun archivo fuera de este wrapper necesita importar
/// firebase_messaging para leer un mensaje.
class RemoteMessageData {
  const RemoteMessageData({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// routine_id / profile_id - ver el payload que arma la Edge Function en
  /// supabase/functions/send-routine-notification/index.ts.
  final Map<String, String> data;
}

abstract interface class PushMessagingGateway {
  /// Null si todavia no hay token (permiso no resuelto, sin conexion la
  /// primera vez, etc.) - quien llama debe tratarlo como "todavia no
  /// registrable", no como un error.
  Future<String?> getToken();

  /// Se dispara cada vez que FCM rota el token mientras la app esta viva.
  Stream<String> get onTokenRefresh;

  Future<PushPermissionStatus> requestPermission();

  /// Mensajes recibidos con la app en primer plano - FCM no los muestra
  /// solo, hay que decidir que hacer (ver push_notifications.dart, que los
  /// re-muestra como notificacion local via flutter_local_notifications).
  Stream<RemoteMessageData> get onMessage;

  /// El usuario toco una notificacion y la app paso de segundo plano a
  /// primer plano por eso.
  Stream<RemoteMessageData> get onMessageOpenedApp;

  /// La app estaba cerrada del todo y se abrio porque el usuario toco una
  /// notificacion - null si se abrio de cualquier otra forma.
  Future<RemoteMessageData?> getInitialMessage();

  Future<void> deleteToken();
}

class FirebaseMessagingGateway implements PushMessagingGateway {
  FirebaseMessagingGateway(this._messaging);

  final fm.FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      fm.AuthorizationStatus.authorized ||
      fm.AuthorizationStatus.provisional =>
        PushPermissionStatus.granted,
      fm.AuthorizationStatus.denied => PushPermissionStatus.denied,
      fm.AuthorizationStatus.notDetermined =>
        PushPermissionStatus.notDetermined,
    };
  }

  @override
  Stream<RemoteMessageData> get onMessage =>
      fm.FirebaseMessaging.onMessage.map(_toRemoteMessageData);

  @override
  Stream<RemoteMessageData> get onMessageOpenedApp =>
      fm.FirebaseMessaging.onMessageOpenedApp.map(_toRemoteMessageData);

  @override
  Future<RemoteMessageData?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toRemoteMessageData(message);
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  RemoteMessageData _toRemoteMessageData(fm.RemoteMessage message) {
    return RemoteMessageData(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}

/// Default de dependencies.dart y de la plataforma web/de escritorio, donde
/// firebase_messaging no esta configurado (o no existe, en el caso de
/// Windows/Linux). Nunca lanza, nunca entrega tokens ni mensajes - la app
/// sigue funcionando exactamente igual que antes de esta etapa en esas
/// plataformas.
class NoOpPushMessagingGateway implements PushMessagingGateway {
  const NoOpPushMessagingGateway();

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.notDetermined;

  @override
  Stream<RemoteMessageData> get onMessage => const Stream.empty();

  @override
  Stream<RemoteMessageData> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<RemoteMessageData?> getInitialMessage() async => null;

  @override
  Future<void> deleteToken() async {}
}
