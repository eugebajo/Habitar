import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';

import 'dependencies.dart';

enum AppRestoreDestination { onboarding, register, profileSetup, dashboard }

class AppRestoreResult {
  const AppRestoreResult({
    required this.destination,
    this.familyId,
    this.profileId,
    this.profileKind,
    this.activeSessionId,
  });

  final AppRestoreDestination destination;
  final String? familyId;
  final String? profileId;
  final ProfileKind? profileKind;
  final String? activeSessionId;
}

class AppRestoreService {
  const AppRestoreService({
    required this.authRepository,
    required this.familyRepository,
    required this.profileRepository,
    required this.sessionRepository,
    this.localStore,
  });

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final ProfileRepository profileRepository;
  final RoutineSessionRepository sessionRepository;
  final LocalStore? localStore;

  Future<AppRestoreResult> restore() async {
    final user = await authRepository.currentUser();
    if (user == null) {
      return const AppRestoreResult(
          destination: AppRestoreDestination.onboarding);
    }

    final family = await _familyForUser(user);
    if (family == null) {
      return const AppRestoreResult(
          destination: AppRestoreDestination.register);
    }

    final childProfiles =
        await profileRepository.childProfiles(family.metadata.id);
    if (childProfiles.isNotEmpty) {
      final profile = childProfiles.first;
      final session =
          await sessionRepository.activeSessionForProfile(profile.metadata.id);
      return AppRestoreResult(
        destination: AppRestoreDestination.dashboard,
        familyId: family.metadata.id,
        profileId: profile.metadata.id,
        profileKind: ProfileKind.child,
        activeSessionId: session?.id,
      );
    }

    final teenProfiles =
        await profileRepository.teenProfiles(family.metadata.id);
    if (teenProfiles.isNotEmpty) {
      final profile = teenProfiles.first;
      final session =
          await sessionRepository.activeSessionForProfile(profile.metadata.id);
      return AppRestoreResult(
        destination: AppRestoreDestination.dashboard,
        familyId: family.metadata.id,
        profileId: profile.metadata.id,
        profileKind: ProfileKind.teen,
        activeSessionId: session?.id,
      );
    }

    return AppRestoreResult(
        destination: AppRestoreDestination.profileSetup,
        familyId: family.metadata.id);
  }

  Future<Family?> _familyForUser(User user) async {
    final directFamily = await familyRepository.currentFamily(user.metadata.id);
    if (directFamily != null) {
      return directFamily;
    }
    return _recoverFamilyLinkedToSameEmail(user);
  }

  Future<Family?> _recoverFamilyLinkedToSameEmail(User user) async {
    final store = localStore;
    if (store == null) {
      return null;
    }
    final normalizedEmail = user.email.trim().toLowerCase();
    String? previousUserId;
    final userRecords = await store.list(LocalStoreCollections.users);
    for (final record in userRecords) {
      final email = (record['email'] as String? ?? '').trim().toLowerCase();
      if (email != normalizedEmail) {
        continue;
      }
      previousUserId = _metadataId(record);
      break;
    }
    if (previousUserId == null) {
      return null;
    }

    final familyRecords = await store.list(LocalStoreCollections.families);
    for (final record in familyRecords) {
      final adultUserIds = _stringList(record['adult_user_ids']);
      if (!adultUserIds.contains(previousUserId)) {
        continue;
      }
      final familyId = _metadataId(record);
      if (familyId == null) {
        continue;
      }
      final updatedIds = [...adultUserIds];
      if (!updatedIds.contains(user.metadata.id)) {
        updatedIds.add(user.metadata.id);
        final updatedRecord = Map<String, Object?>.from(record);
        updatedRecord['adult_user_ids'] = updatedIds;
        await store.put(
            LocalStoreCollections.families, familyId, updatedRecord);
        return _familyFromRecord(updatedRecord);
      }
      return _familyFromRecord(record);
    }
    return null;
  }

  String? _metadataId(Map<String, Object?> record) {
    final metadata = record['metadata'];
    if (metadata is Map) {
      return metadata['id'] as String?;
    }
    return null;
  }

  Family _familyFromRecord(Map<String, Object?> record) {
    final metadata = (record['metadata'] as Map).cast<String, Object?>();
    return Family(
      metadata: EntityMetadata(
        id: metadata['id'] as String,
        createdAt: DateTime.parse(metadata['created_at'] as String),
        updatedAt: DateTime.parse(metadata['updated_at'] as String),
        ownerId: metadata['owner_id'] as String,
        status: EntityStatus.values.byName(
          metadata['status'] as String? ?? EntityStatus.active.name,
        ),
      ),
      name: record['name'] as String,
      adultUserIds: _stringList(record['adult_user_ids']),
    );
  }

  List<String> _stringList(Object? value) =>
      (value as List? ?? const []).map((item) => item.toString()).toList();
}

final appRestoreServiceProvider = Provider<AppRestoreService>((ref) {
  return AppRestoreService(
    authRepository: ref.watch(authRepositoryProvider),
    familyRepository: ref.watch(familyRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
    localStore: ref.watch(localStoreProvider),
  );
});

final appRestoreProvider = FutureProvider<AppRestoreResult>((ref) async {
  final result = await ref.watch(appRestoreServiceProvider).restore();
  ref.read(currentFamilyIdProvider.notifier).state = result.familyId;
  ref.read(currentProfileIdProvider.notifier).state = result.profileId;
  ref.read(currentProfileKindProvider.notifier).state = result.profileKind;
  ref.read(currentRoutineSessionIdProvider.notifier).state =
      result.activeSessionId;
  return result;
});
