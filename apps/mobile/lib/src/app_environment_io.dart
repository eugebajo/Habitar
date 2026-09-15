import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fm;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dependencies.dart';
import 'platform/native_reminder_scheduler.dart';
import 'platform/push_messaging_gateway.dart';
import 'platform/supabase_flutter_auth_gateway.dart';

Future<List<Override>> buildProductionOverrides() async {
  final directory = await getApplicationSupportDirectory();
  final store = await DriftLocalStore.open(
      File('${directory.path}${Platform.pathSeparator}habitar.sqlite'));
  final supabaseConfig = SupabaseConfig.maybeFromEnvironment();
  if (kReleaseMode && supabaseConfig == null) {
    throw StateError(
      'Release builds require SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.',
    );
  }

  final supabaseClient =
      supabaseConfig == null ? null : await _initializeSupabase(supabaseConfig);
  final authRepository = supabaseClient == null
      ? LocalAuthRepository(store)
      : SupabaseAuthRepository(FlutterSupabaseAuthGateway(supabaseClient));
  final reminderScheduler = Platform.isAndroid || Platform.isIOS
      ? await NativeReminderScheduler.create()
      : InMemoryReminderScheduler();
  // Etapa 3 (notificaciones push): firebase_core/firebase_messaging solo
  // soportan Android/iOS/web/macOS - nunca Windows ni Linux de
  // escritorio, que sí caen en esta rama "io" (dart:io existe ahi
  // tambien). Mismo guard que reminderScheduler arriba, mismo motivo:
  // Platform.isAndroid || Platform.isIOS, no "todo lo que no es web".
  // google-services.json (Android) ya esta en su lugar - Firebase.
  // initializeApp() sin `options` lo lee solo via el plugin de Gradle, no
  // hace falta firebase_options.dart mientras no haya un target de iOS
  // configurado.
  final pushMessagingGateway =
      Platform.isAndroid || Platform.isIOS
          ? await _initializeFirebaseMessaging()
          : const NoOpPushMessagingGateway();

  return [
    localStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(authRepository),
    familyRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalFamilyRepository(store)
        : SupabaseFamilyRepository(supabaseClient)),
    profileRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalProfileRepository(store)
        : SupabaseProfileRepository(supabaseClient)),
    routineRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalRoutineRepository(store)
        : SupabaseRoutineRepository(supabaseClient)),
    adultProfileRepositoryProvider
        .overrideWithValue(LocalAdultProfileRepository(store)),
    routineSessionRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalRoutineSessionRepository(store)
        : SupabaseRoutineSessionRepository(supabaseClient)),
    familyActivityEventRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalFamilyActivityEventRepository(store)
        : SupabaseFamilyActivityEventRepository(supabaseClient)),
    routineOverrideRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalRoutineOverrideRepository(store)
        : SupabaseRoutineOverrideRepository(supabaseClient)),
    habitRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalHabitRepository(store)
        : SupabaseHabitRepository(supabaseClient)),
    habitProgressRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalHabitProgressRepository(store)
        : SupabaseHabitProgressRepository(supabaseClient)),
    timeBankRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalTimeBankRepository(store)
        : SupabaseTimeBankRepository(supabaseClient)),
    notificationPreferenceRepositoryProvider
        .overrideWithValue(LocalNotificationPreferenceRepository(store)),
    reminderSchedulerProvider.overrideWithValue(reminderScheduler),
    emotionCheckInRepositoryProvider
        .overrideWithValue(LocalEmotionCheckInRepository(store)),
    supportRequestRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalSupportRequestRepository(store)
        : SupabaseSupportRequestRepository(supabaseClient)),
    storyProgressRepositoryProvider
        .overrideWithValue(LocalStoryProgressRepository(store)),
    wearableGatewayRepositoryProvider
        .overrideWithValue(LocalWearableGatewayRepository(store)),
    syncQueueRepositoryProvider
        .overrideWithValue(LocalSyncQueueRepository(store)),
    deviceTokenRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalDeviceTokenRepository(store)
        : SupabaseDeviceTokenRepository(supabaseClient)),
    pushNotificationPreferenceRepositoryProvider.overrideWithValue(
        supabaseClient == null
            ? LocalPushNotificationPreferenceRepository(store)
            : SupabasePushNotificationPreferenceRepository(supabaseClient)),
    pushMessagingGatewayProvider.overrideWithValue(pushMessagingGateway),
  ];
}

Future<SupabaseClient> _initializeSupabase(SupabaseConfig config) async {
  await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  return Supabase.instance.client;
}

/// Sin `options`: Firebase.initializeApp() sin argumentos lee la
/// configuracion desde google-services.json en tiempo de build (via el
/// plugin de Gradle, ya aplicado en android/app/build.gradle.kts) - no
/// hace falta firebase_options.dart (que genera `flutterfire configure`)
/// mientras la unica plataforma configurada sea Android. Si en el futuro
/// se agrega iOS, ahi si va a hacer falta correr `flutterfire configure` y
/// pasar `options: DefaultFirebaseOptions.currentPlatform`.
Future<PushMessagingGateway> _initializeFirebaseMessaging() async {
  await Firebase.initializeApp();
  return FirebaseMessagingGateway(fm.FirebaseMessaging.instance);
}
