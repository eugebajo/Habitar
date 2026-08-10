import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';

import 'dependencies.dart';

class SelectedHabitarProfile {
  const SelectedHabitarProfile({
    required this.id,
    required this.familyId,
    required this.displayName,
    required this.age,
    required this.kind,
  });

  final String id;
  final String familyId;
  final String displayName;
  final int age;
  final ProfileKind kind;
}

final selectedProfileProvider = FutureProvider<SelectedHabitarProfile?>(
  (ref) => SelectedProfileResolver(
    familyId: ref.read(currentFamilyIdProvider),
    selectedId: ref.read(currentProfileIdProvider),
    profileRepository: ref.read(profileRepositoryProvider),
    onAutoSelect: (id, kind) {
      ref.read(currentProfileIdProvider.notifier).state = id;
      ref.read(currentProfileKindProvider.notifier).state = kind;
    },
  ).resolve(),
);

Future<SelectedHabitarProfile?> loadSelectedProfile(WidgetRef ref) async {
  return SelectedProfileResolver(
    familyId: ref.read(currentFamilyIdProvider),
    selectedId: ref.read(currentProfileIdProvider),
    profileRepository: ref.read(profileRepositoryProvider),
    onAutoSelect: (id, kind) {
      ref.read(currentProfileIdProvider.notifier).state = id;
      ref.read(currentProfileKindProvider.notifier).state = kind;
    },
  ).resolve();
}

class SelectedProfileResolver {
  const SelectedProfileResolver({
    required this.familyId,
    required this.selectedId,
    required this.profileRepository,
    this.onAutoSelect,
  });

  final String? familyId;
  final String? selectedId;
  final ProfileRepository profileRepository;
  final void Function(String id, ProfileKind kind)? onAutoSelect;

  Future<SelectedHabitarProfile?> resolve() async {
    final familyId = this.familyId;
    if (familyId == null) {
      return null;
    }

    final childProfiles = await profileRepository.childProfiles(familyId);
    final teenProfiles = await profileRepository.teenProfiles(familyId);

    for (final profile in childProfiles) {
      if (profile.metadata.id == selectedId) {
        return SelectedHabitarProfile(
          id: profile.metadata.id,
          familyId: profile.familyId,
          displayName: profile.displayName,
          age: profile.age,
          kind: ProfileKind.child,
        );
      }
    }

    for (final profile in teenProfiles) {
      if (profile.metadata.id == selectedId) {
        return SelectedHabitarProfile(
          id: profile.metadata.id,
          familyId: profile.familyId,
          displayName: profile.displayName,
          age: profile.age,
          kind: ProfileKind.teen,
        );
      }
    }

    if (selectedId != null) {
      return null;
    }

    if (childProfiles.isNotEmpty) {
      final profile = childProfiles.first;
      onAutoSelect?.call(profile.metadata.id, ProfileKind.child);
      return SelectedHabitarProfile(
        id: profile.metadata.id,
        familyId: profile.familyId,
        displayName: profile.displayName,
        age: profile.age,
        kind: ProfileKind.child,
      );
    }

    if (teenProfiles.isNotEmpty) {
      final profile = teenProfiles.first;
      onAutoSelect?.call(profile.metadata.id, ProfileKind.teen);
      return SelectedHabitarProfile(
        id: profile.metadata.id,
        familyId: profile.familyId,
        displayName: profile.displayName,
        age: profile.age,
        kind: ProfileKind.teen,
      );
    }

    return null;
  }
}
