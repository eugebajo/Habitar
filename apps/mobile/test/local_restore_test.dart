import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/local_restore.dart';

void main() {
  test('restore sends empty local state to registration', () async {
    final service = AppRestoreService(
      authRepository: InMemoryAuthRepository(),
      familyRepository: InMemoryFamilyRepository(),
      profileRepository: InMemoryProfileRepository(),
      sessionRepository: InMemoryRoutineSessionRepository(),
    );

    final result = await service.restore();

    expect(result.destination, AppRestoreDestination.register);
  });

  test('restore recovers family and first child profile', () async {
    final authRepository = InMemoryAuthRepository();
    final familyRepository = InMemoryFamilyRepository();
    final profileRepository = InMemoryProfileRepository();
    final user = await authRepository.registerAdult(
      displayName: 'Adulto',
      email: 'adulto@example.com',
      password: 'demo',
    );
    final family = await familyRepository.createFamily(
      ownerUserId: user.metadata.id,
      name: 'Casa',
    );
    final profile = await profileRepository.createChildProfile(
      familyId: family.metadata.id,
      displayName: 'Perfil',
      age: 9,
    );
    final service = AppRestoreService(
      authRepository: authRepository,
      familyRepository: familyRepository,
      profileRepository: profileRepository,
      sessionRepository: InMemoryRoutineSessionRepository(),
    );

    final result = await service.restore();

    expect(result.destination, AppRestoreDestination.dashboard);
    expect(result.familyId, family.metadata.id);
    expect(result.profileId, profile.metadata.id);
    expect(result.profileKind, ProfileKind.child);
  });
}
