import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';

import 'dependencies.dart';

enum AppRestoreDestination {
  onboarding,
  register,
  invitation,
  profileSetup,
  dashboard,
}

class AppRestoreResult {
  const AppRestoreResult({
    required this.destination,
    this.familyId,
    this.profileId,
    this.profileKind,
    this.activeSessionId,
    this.pendingInvitation,
    this.departureNotices = const [],
  });

  final AppRestoreDestination destination;
  final String? familyId;
  final String? profileId;
  final ProfileKind? profileKind;
  final String? activeSessionId;
  final PendingFamilyInvitation? pendingInvitation;

  /// Notices waiting for the signed-in adult because a family they
  /// belonged to was deleted by someone else while they weren't using the
  /// app - see FamilyRepository.departureNotices. Always empty when
  /// destination is onboarding (no signed-in user to owe a notice to).
  final List<FamilyDepartureNotice> departureNotices;
}

class AppRestoreService {
  const AppRestoreService({
    required this.authRepository,
    required this.familyRepository,
    required this.profileRepository,
    required this.sessionRepository,
    this.localStore,
    this.allowLocalFamilyRecovery = true,
  });

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final ProfileRepository profileRepository;
  final RoutineSessionRepository sessionRepository;
  final LocalStore? localStore;
  final bool allowLocalFamilyRecovery;

  Future<AppRestoreResult> restore() async {
    final user = await authRepository.currentUser();
    if (user == null) {
      _debugLog('RESTORE:');
      _debugLog('membership found: NO');
      _debugLog('pending invitations count: 0');
      _debugLog('destination: onboarding');
      return const AppRestoreResult(
          destination: AppRestoreDestination.onboarding);
    }

    _debugLog('RESTORE:');

    // Best-effort: a family this adult belonged to may have been deleted
    // by its owner (see delete_family in
    // supabase/migrations/0014_family_deletion.sql) while they weren't
    // using the app. Fetching this never blocks restore - if it fails for
    // any reason, the notice just doesn't show this launch; the row stays
    // in the table for the next one.
    var departureNotices = const <FamilyDepartureNotice>[];
    try {
      departureNotices = await familyRepository.departureNotices(user.metadata.id);
    } catch (_) {
      // ignore - see comment above.
    }

    final family = await _familyForUser(user);
    if (family == null) {
      final invitations =
          await familyRepository.pendingInvitationsForEmail(user.email);
      _debugLog('membership found: NO');
      _debugLog('pending invitations count: ${invitations.length}');
      if (invitations.isNotEmpty) {
        _debugLog('destination: invitation');
        return AppRestoreResult(
          destination: AppRestoreDestination.invitation,
          pendingInvitation: invitations.first,
          departureNotices: departureNotices,
        );
      }
      _debugLog('destination: register');
      return AppRestoreResult(
        destination: AppRestoreDestination.register,
        departureNotices: departureNotices,
      );
    }

    _debugLog('membership found: YES');
    final childProfiles =
        await profileRepository.childProfiles(family.metadata.id);
    if (childProfiles.isNotEmpty) {
      final profile = childProfiles.first;
      final session =
          await sessionRepository.activeSessionForProfile(profile.metadata.id);
      _debugLog('pending invitations count: 0');
      _debugLog('destination: dashboard');
      return AppRestoreResult(
        destination: AppRestoreDestination.dashboard,
        familyId: family.metadata.id,
        profileId: profile.metadata.id,
        profileKind: ProfileKind.child,
        activeSessionId: session?.id,
        departureNotices: departureNotices,
      );
    }

    final teenProfiles =
        await profileRepository.teenProfiles(family.metadata.id);
    if (teenProfiles.isNotEmpty) {
      final profile = teenProfiles.first;
      final session =
          await sessionRepository.activeSessionForProfile(profile.metadata.id);
      _debugLog('pending invitations count: 0');
      _debugLog('destination: dashboard');
      return AppRestoreResult(
        destination: AppRestoreDestination.dashboard,
        familyId: family.metadata.id,
        profileId: profile.metadata.id,
        profileKind: ProfileKind.teen,
        activeSessionId: session?.id,
        departureNotices: departureNotices,
      );
    }

    _debugLog('pending invitations count: 0');
    _debugLog('destination: profileSetup');
    return AppRestoreResult(
        destination: AppRestoreDestination.profileSetup,
        familyId: family.metadata.id,
        departureNotices: departureNotices);
  }

  Future<Family?> _familyForUser(User user) async {
    final directFamily = await familyRepository.currentFamily(user.metadata.id);
    if (directFamily != null) {
      return directFamily;
    }
    final bootstrappedFamily = await _completePendingBootstrap(user);
    if (bootstrappedFamily != null) {
      return bootstrappedFamily;
    }
    if (!allowLocalFamilyRecovery) {
      return null;
    }
    return _recoverFamilyLinkedToSameEmail(user);
  }

  Future<Family?> _completePendingBootstrap(User user) async {
    final store = localStore;
    if (store == null) {
      return null;
    }

    final normalizedEmail = user.email.trim().toLowerCase();
    final pending = await store.get(
      LocalStoreCollections.pendingFamilyBootstrap,
      normalizedEmail,
    );
    if (pending == null || pending['completed'] == true) {
      return null;
    }

    final familyName = (pending['family_name'] as String? ?? '').trim();
    if (familyName.isEmpty) {
      return null;
    }

    final family = await familyRepository.createFamily(
      ownerUserId: user.metadata.id,
      name: familyName,
    );
    final updated = Map<String, Object?>.from(pending);
    updated['completed'] = true;
    updated['completed_at'] = DateTime.now().toUtc().toIso8601String();
    await store.put(
      LocalStoreCollections.pendingFamilyBootstrap,
      normalizedEmail,
      updated,
    );
    return family;
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
  final familyRepository = ref.watch(familyRepositoryProvider);
  return AppRestoreService(
    authRepository: ref.watch(authRepositoryProvider),
    familyRepository: familyRepository,
    profileRepository: ref.watch(profileRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
    localStore: ref.watch(localStoreProvider),
    allowLocalFamilyRecovery: familyRepository is! SupabaseFamilyRepository,
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

void _debugLog(String message) {
  assert(() {
    // Development-only diagnostics. Do not log passwords, tokens or secrets.
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
