import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dependencies.dart';
import 'platform/native_reminder_scheduler.dart';
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
  ];
}

Future<SupabaseClient> _initializeSupabase(SupabaseConfig config) async {
  await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  return Supabase.instance.client;
}
