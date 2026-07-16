import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';

import 'dependencies.dart';

enum AppRestoreDestination { register, profileSetup, dashboard }

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
  });

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final ProfileRepository profileRepository;
  final RoutineSessionRepository sessionRepository;

  Future<AppRestoreResult> restore() async {
    final user = await authRepository.currentUser();
    if (user == null) {
      return const AppRestoreResult(
          destination: AppRestoreDestination.register);
    }

    final family = await familyRepository.currentFamily(user.metadata.id);
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
}

final appRestoreServiceProvider = Provider<AppRestoreService>((ref) {
  return AppRestoreService(
    authRepository: ref.watch(authRepositoryProvider),
    familyRepository: ref.watch(familyRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    sessionRepository: ref.watch(routineSessionRepositoryProvider),
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
