import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import 'dependencies.dart';
import 'platform/supabase_flutter_auth_gateway.dart';

Future<List<Override>> buildProductionOverrides() async {
  final store = BrowserLocalStore('habitar');
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

class BrowserLocalStore implements LocalStore {
  BrowserLocalStore(this.namespace);

  final String namespace;

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final raw = web.window.localStorage.getItem(_key(collection, id));
    if (raw == null) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.cast<String, Object?>();
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) async {
    final prefix = _prefix(collection);
    final storage = web.window.localStorage;
    final records = <Map<String, Object?>>[];
    for (var index = 0; index < storage.length; index += 1) {
      final key = storage.key(index);
      if (key == null) {
        continue;
      }
      if (!key.startsWith(prefix)) {
        continue;
      }
      final raw = storage.getItem(key);
      if (raw == null) {
        continue;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      records.add(decoded.cast<String, Object?>());
    }
    return records;
  }

  @override
  Future<void> put(
      String collection, String id, Map<String, Object?> value) async {
    web.window.localStorage.setItem(_key(collection, id), jsonEncode(value));
  }

  @override
  Future<void> delete(String collection, String id) async {
    web.window.localStorage.removeItem(_key(collection, id));
  }

  String _prefix(String collection) => '$namespace::$collection::';

  String _key(String collection, String id) => '${_prefix(collection)}$id';
}
