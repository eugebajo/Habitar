import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_data/data.dart';
import 'package:path_provider/path_provider.dart';

import 'dependencies.dart';

Future<List<Override>> buildProductionOverrides() async {
  final directory = await getApplicationSupportDirectory();
  final store = FileLocalStore(
      File('${directory.path}${Platform.pathSeparator}habitar_store.json'));

  return [
    localStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(LocalAuthRepository(store)),
    familyRepositoryProvider.overrideWithValue(LocalFamilyRepository(store)),
    profileRepositoryProvider.overrideWithValue(LocalProfileRepository(store)),
    routineRepositoryProvider.overrideWithValue(LocalRoutineRepository(store)),
    routineSessionRepositoryProvider
        .overrideWithValue(LocalRoutineSessionRepository(store)),
    habitRepositoryProvider.overrideWithValue(LocalHabitRepository(store)),
    habitProgressRepositoryProvider
        .overrideWithValue(LocalHabitProgressRepository(store)),
  ];
}
