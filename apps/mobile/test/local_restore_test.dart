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
      displayName: 'Perfil local',
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

  test('supabase restore does not mix same-email local family data', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_remote_restore_test_');
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
    await familyRepository.createFamily(
      ownerUserId: oldUser.metadata.id,
      name: 'Casa local',
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
      allowLocalFamilyRecovery: false,
    );

    final result = await service.restore();
    final linkedFamily = await familyRepository.currentFamily('remote-user-id');

    expect(result.destination, AppRestoreDestination.register);
    expect(result.familyId, isNull);
    expect(result.profileId, isNull);
    expect(linkedFamily, isNull);
  });

  test('restore completes pending family bootstrap after email confirmation',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_bootstrap_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final familyRepository = LocalFamilyRepository(store);
    final profileRepository = LocalProfileRepository(store);
    final user = User(
      metadata: EntityMetadata(
        id: 'confirmed-user-id',
        createdAt: _testDate,
        updatedAt: _testDate,
        ownerId: 'confirmed-user-id',
      ),
      displayName: 'Euge',
      email: 'euge@example.com',
    );
    await store.put(
      LocalStoreCollections.pendingFamilyBootstrap,
      'euge@example.com',
      {
        'email': 'euge@example.com',
        'display_name': 'Euge',
        'family_name': 'Casa familiar',
        'created_at': _testDate.toUtc().toIso8601String(),
        'completed': false,
      },
    );
    final service = AppRestoreService(
      authRepository: _FixedAuthRepository(user),
      familyRepository: familyRepository,
      profileRepository: profileRepository,
      sessionRepository: LocalRoutineSessionRepository(store),
      localStore: store,
    );

    final result = await service.restore();
    final family = await familyRepository.currentFamily(user.metadata.id);
    final pending = await store.get(
      LocalStoreCollections.pendingFamilyBootstrap,
      'euge@example.com',
    );

    expect(result.destination, AppRestoreDestination.profileSetup);
    expect(result.familyId, family?.metadata.id);
    expect(family?.name, 'Casa familiar');
    expect(pending?['completed'], isTrue);
    expect(pending?.containsKey('password'), isFalse);
  });

  test('restore sends invited adult without membership to invitation screen',
      () async {
    final authRepository = InMemoryAuthRepository();
    final familyRepository = InMemoryFamilyRepository();
    final profileRepository = InMemoryProfileRepository();
    final owner = await authRepository.registerAdult(
      displayName: 'Adulto A',
      email: 'adulto-a@example.com',
      password: 'demo',
    );
    final family = await familyRepository.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Familia compartida',
    );
    final child = await profileRepository.createChildProfile(
      familyId: family.metadata.id,
      displayName: 'Nico',
      age: 9,
    );
    final invitation = await familyRepository.createAdultInvitation(
      familyId: family.metadata.id,
      email: 'adulto-b@example.com',
      role: FamilyMemberRole.caregiver,
      invitedByUserId: owner.metadata.id,
    );
    final invited = await authRepository.registerAdult(
      displayName: 'Adulto B',
      email: 'adulto-b@example.com',
      password: 'demo',
    );
    final service = AppRestoreService(
      authRepository: authRepository,
      familyRepository: familyRepository,
      profileRepository: profileRepository,
      sessionRepository: InMemoryRoutineSessionRepository(),
    );

    final result = await service.restore();

    expect(result.destination, AppRestoreDestination.invitation);
    expect(result.familyId, isNull);
    expect(result.pendingInvitation?.invitation.metadata.id,
        invitation.metadata.id);
    expect(result.pendingInvitation?.familyName, 'Familia compartida');

    final member = await familyRepository.acceptInvitation(
      invitationId: invitation.metadata.id,
      userId: invited.metadata.id,
      userEmail: invited.email,
    );
    final acceptedFamily =
        await familyRepository.currentFamily(invited.metadata.id);
    final profiles =
        await profileRepository.childProfiles(acceptedFamily!.metadata.id);

    expect(member.familyId, family.metadata.id);
    expect(member.role, FamilyMemberRole.caregiver);
    expect(acceptedFamily.metadata.id, family.metadata.id);
    expect(profiles.single.metadata.id, child.metadata.id);
  });

  test('restore lets adult without membership and without invitation register',
      () async {
    final authRepository = InMemoryAuthRepository();
    await authRepository.registerAdult(
      displayName: 'Adulto B',
      email: 'sin-invitacion@example.com',
      password: 'demo',
    );
    final service = AppRestoreService(
      authRepository: authRepository,
      familyRepository: InMemoryFamilyRepository(),
      profileRepository: InMemoryProfileRepository(),
      sessionRepository: InMemoryRoutineSessionRepository(),
    );

    final result = await service.restore();

    expect(result.destination, AppRestoreDestination.register);
    expect(result.pendingInvitation, isNull);
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

  @override
  Future<void> requestPasswordReset({
    required String email,
    required Uri redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({required String password}) async {}
}
