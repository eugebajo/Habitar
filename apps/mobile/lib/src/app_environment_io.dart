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

  final authRepository = supabaseConfig == null
      ? LocalAuthRepository(store)
      : await _buildSupabaseAuthRepository(supabaseConfig);

  return [
    localStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(authRepository),
    familyRepositoryProvider.overrideWithValue(LocalFamilyRepository(store)),
    profileRepositoryProvider.overrideWithValue(LocalProfileRepository(store)),
    routineRepositoryProvider.overrideWithValue(LocalRoutineRepository(store)),
    routineSessionRepositoryProvider
        .overrideWithValue(LocalRoutineSessionRepository(store)),
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

Future<SupabaseAuthRepository> _buildSupabaseAuthRepository(
    SupabaseConfig config) async {
  await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  return SupabaseAuthRepository(
      FlutterSupabaseAuthGateway(Supabase.instance.client));
}
