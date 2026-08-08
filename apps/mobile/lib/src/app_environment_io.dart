import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_data/data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dependencies.dart';
import 'platform/supabase_flutter_auth_gateway.dart';

Future<List<Override>> buildProductionOverrides() async {
  final directory = await getApplicationSupportDirectory();
  final store = await DriftLocalStore.open(
      File('${directory.path}${Platform.pathSeparator}habitar.sqlite'));
  final supabaseConfig = SupabaseConfig.maybeFromEnvironment();

  final supabaseClient =
      supabaseConfig == null ? null : await _initializeSupabase(supabaseConfig);
  final authRepository = supabaseClient == null
      ? LocalAuthRepository(store)
      : SupabaseAuthRepository(FlutterSupabaseAuthGateway(supabaseClient));

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
    routineSessionRepositoryProvider
        .overrideWithValue(LocalRoutineSessionRepository(store)),
    routineOverrideRepositoryProvider.overrideWithValue(supabaseClient == null
        ? LocalRoutineOverrideRepository(store)
        : SupabaseRoutineOverrideRepository(supabaseClient)),
    habitRepositoryProvider.overrideWithValue(LocalHabitRepository(store)),
    habitProgressRepositoryProvider
        .overrideWithValue(LocalHabitProgressRepository(store)),
    notificationPreferenceRepositoryProvider
        .overrideWithValue(LocalNotificationPreferenceRepository(store)),
    emotionCheckInRepositoryProvider
        .overrideWithValue(LocalEmotionCheckInRepository(store)),
    supportRequestRepositoryProvider
        .overrideWithValue(LocalSupportRequestRepository(store)),
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
