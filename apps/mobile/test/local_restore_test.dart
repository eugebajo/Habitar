import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/local_restore.dart';

void main() {
  test('restore sends empty local state to onboarding', () async {
    final service = AppRestoreService(
      authRepository: InMemoryAuthRepository(),
      familyRepository: InMemoryFamilyRepository(),
      profileRepository: InMemoryProfileRepository(),
      sessionRepository: InMemoryRoutineSessionRepository(),
    );

    final result = await service.restore();

    expect(result.destination, AppRestoreDestination.onboarding);
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
  test('restore links a signed-in adult to a local family with the same email',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_restore_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final localAuth = LocalAuthRepository(store);
    final familyRepository = LocalFamilyRepository(store);
    final profileRepository = LocalProfileRepository(store);
    final oldUser = await localAuth.registerAdult(
      displayName: 'Euge',
      email: 'euge@example.com',
      password: 'local',
    );
    final family = await familyRepository.createFamily(
      ownerUserId: oldUser.metadata.id,
      name: 'Casa',
    );
    final profile = await profileRepository.createChildProfile(
      familyId: family.metadata.id,
      displayName: 'Tomi',
      age: 9,
    );
    await localAuth.signOut();

    final service = AppRestoreService(
      authRepository: _FixedAuthRepository(
        User(
          metadata: EntityMetadata(
            id: 'remote-user-id',
            createdAt: _testDate,
            updatedAt: _testDate,
            ownerId: 'remote-user-id',
          ),
          displayName: 'Euge',
          email: 'euge@example.com',
        ),
      ),
      familyRepository: familyRepository,
      profileRepository: profileRepository,
      sessionRepository: LocalRoutineSessionRepository(store),
      localStore: store,
    );

    final result = await service.restore();
    final linkedFamily = await familyRepository.currentFamily('remote-user-id');

    expect(result.destination, AppRestoreDestination.dashboard);
    expect(result.familyId, family.metadata.id);
    expect(result.profileId, profile.metadata.id);
    expect(linkedFamily?.metadata.id, family.metadata.id);
  });
}

final _testDate = DateTime(2026, 8, 7);

class _FixedAuthRepository implements AuthRepository {
  const _FixedAuthRepository(this.user);

  final User user;

  @override
  Future<User?> currentUser() async => user;

  @override
  Future<User> registerAdult({
    required String displayName,
    required String email,
    required String password,
  }) async =>
      user;

  @override
  Future<User> signIn(
          {required String email, required String password}) async =>
      user;

  @override
  Future<void> signOut() async {}
}
