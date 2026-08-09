import 'dart:io';

import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('persists core family setup across store instances', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/habitar.json');

    final firstStore = FileLocalStore(file);
    final authRepository = LocalAuthRepository(firstStore);
    final familyRepository = LocalFamilyRepository(firstStore);
    final profileRepository = LocalProfileRepository(firstStore);

    final user = await authRepository.registerAdult(
      displayName: 'Euge',
      email: 'euge@example.com',
      password: 'not-stored-locally',
    );
    final family = await familyRepository.createFamily(
        ownerUserId: user.metadata.id, name: 'Casa');
    await profileRepository.createChildProfile(
        familyId: family.metadata.id, displayName: 'Luz', age: 8);

    final secondStore = FileLocalStore(file);
    final restoredUser = await LocalAuthRepository(secondStore).currentUser();
    final restoredFamily = await LocalFamilyRepository(secondStore)
        .currentFamily(user.metadata.id);
    final restoredProfiles = await LocalProfileRepository(secondStore)
        .childProfiles(family.metadata.id);

    expect(restoredUser?.email, 'euge@example.com');
    expect(restoredFamily?.name, 'Casa');
    expect(restoredProfiles.single.displayName, 'Luz');
  });

  test('signs local users out and back in by email', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = LocalAuthRepository(
      FileLocalStore(File('${directory.path}/habitar.json')),
    );

    await repository.registerAdult(
      displayName: 'Euge',
      email: 'euge@example.com',
      password: 'not-stored-locally',
    );

    await repository.signOut();
    expect(await repository.currentUser(), isNull);

    final user = await repository.signIn(
      email: 'euge@example.com',
      password: 'not-stored-locally',
    );

    expect(user.displayName, 'Euge');
    expect((await repository.currentUser())?.email, 'euge@example.com');
  });

  test('persists routines, active sessions, habits and progress', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/habitar.json');
    final store = FileLocalStore(file);

    final routineRepository = LocalRoutineRepository(store);
    final sessionRepository = LocalRoutineSessionRepository(store);
    final habitRepository = LocalHabitRepository(store);
    final progressRepository = LocalHabitProgressRepository(store);

    final routine = await routineRepository.createRoutine(
      profileId: 'profile-1',
      title: 'Manana',
      stepTitles: ['Vestirse', 'Desayunar', 'Mochila'],
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final session = const RoutineEngine().start(
      sessionId: 'session-1',
      routine: routine,
      steps: steps,
      now: DateTime.utc(2026, 7, 15, 12),
    );
    await sessionRepository.save(session);
    final habit = await habitRepository.proposeHabit(
      profileId: 'profile-1',
      title: 'Tomar agua',
      minimumVersion: 'Un vaso',
      status: HabitStatus.newHabit,
    );
    await progressRepository.record(
      HabitProgressEntry(
        habitId: habit.metadata.id,
        recordedAt: DateTime.utc(2026, 7, 15, 13),
        completedMinimumVersion: true,
        helpLevel: 1,
        ease: 4,
      ),
    );

    final restoredStore = FileLocalStore(file);
    final restoredRoutines = await LocalRoutineRepository(restoredStore)
        .routinesForProfile('profile-1');
    final restoredSession = await LocalRoutineSessionRepository(restoredStore)
        .activeSessionForProfile('profile-1');
    final restoredHabits =
        await LocalHabitRepository(restoredStore).habitsForProfile('profile-1');
    final restoredEntries = await LocalHabitProgressRepository(restoredStore)
        .entriesForHabit(habit.metadata.id);

    expect(restoredRoutines.single.title, 'Manana');
    expect(restoredSession?.activeStep?.title, 'Vestirse');
    expect(restoredHabits.single.minimumVersion, 'Un vaso');
    expect(restoredEntries.single.completedMinimumVersion, isTrue);
  });

  test('persists notifications, wellbeing, story progress and wearables',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/habitar.json');
    final store = FileLocalStore(file);
    final now = DateTime.utc(2026, 7, 15, 14);
    final metadata = EntityMetadata(
      id: 'entry-1',
      createdAt: now,
      updatedAt: now,
      ownerId: 'profile-1',
    );

    await LocalNotificationPreferenceRepository(store).saveConsent(
      const NotificationConsent(
        profileId: 'profile-1',
        permissionStatus: NotificationPermissionStatus.granted,
        intensity: ReminderIntensity.visible,
        allowedFeatures: [NotificationPlatformFeature.timeSensitive],
      ),
    );
    await LocalEmotionCheckInRepository(store).save(
      EmotionCheckIn(
        metadata: metadata,
        profileId: 'profile-1',
        emotion: 'tranquilo',
        energyLevel: 3,
      ),
    );
    await LocalSupportRequestRepository(store).save(
      SupportRequest(
        metadata: metadata,
        profileId: 'profile-1',
        kind: 'pausa',
        note: 'Necesita bajar estimulo',
      ),
    );
    await LocalStoryProgressRepository(store).save(
      StoryProgress(
        metadata: metadata,
        storyId: 'cuento-1',
        profileId: 'profile-1',
        isFavorite: true,
      ),
    );
    await LocalWearableGatewayRepository(store).publishSnapshot(
      WearablePlatform.wearOS,
      WearableRoutineSnapshot(
        sessionId: 'session-1',
        routineTitle: 'Manana',
        currentStepTitle: 'Vestirse',
        nextStepTitle: 'Desayunar',
        progressFraction: 0.25,
        remainingMinutes: 12,
        status: RoutineSessionStatus.running,
        updatedAt: now,
      ),
    );

    final restoredStore = FileLocalStore(file);
    final consent = await LocalNotificationPreferenceRepository(restoredStore)
        .consentForProfile('profile-1');
    final checkIns = await LocalEmotionCheckInRepository(restoredStore)
        .entriesForProfile('profile-1');
    final supportRequests = await LocalSupportRequestRepository(restoredStore)
        .requestsForProfile('profile-1');
    final storyProgress = await LocalStoryProgressRepository(restoredStore)
        .progressForProfile('profile-1');
    final wearableStatus = await LocalWearableGatewayRepository(restoredStore)
        .status(WearablePlatform.wearOS);

    expect(consent?.intensity, ReminderIntensity.visible);
    expect(checkIns.single.emotion, 'tranquilo');
    expect(supportRequests.single.kind, 'pausa');
    expect(storyProgress.single.isFavorite, isTrue);
    expect(wearableStatus, WearableConnectionStatus.syncing);
  });

  test('persists time bank benefits and usage', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/habitar.json');
    final store = FileLocalStore(file);
    final repository = LocalTimeBankRepository(store);
    final service = TimeBankService(repository: repository);

    final benefit = await service.grantTime(
      const GrantTimeBenefitInput(
        profileId: 'profile-1',
        description: '10 minutos por empezar',
        minutes: 10,
        idempotencyKey: 'routine-1-started',
        sourceAction: 'comenzar',
      ),
    );
    final duplicate = await service.grantTime(
      const GrantTimeBenefitInput(
        profileId: 'profile-1',
        description: '10 minutos por empezar',
        minutes: 10,
        idempotencyKey: 'routine-1-started',
        sourceAction: 'comenzar',
      ),
    );
    await service.useMinutes(profileId: 'profile-1', minutes: 5);

    final restoredService = TimeBankService(
      repository: LocalTimeBankRepository(FileLocalStore(file)),
    );
    final summary = await restoredService.summaryForProfile('profile-1');

    expect(duplicate.metadata.id, benefit.metadata.id);
    expect(summary.availableMinutes, 5);
    expect(summary.usedMinutes, 5);
    expect(summary.benefits, hasLength(1));
  });
  test('persists sync queue state transitions', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = LocalSyncQueueRepository(
        FileLocalStore(File('${directory.path}/habitar.json')));

    final item = await repository.enqueue(
      collection: LocalStoreCollections.routines,
      entityId: 'routine-1',
      operation: SyncOperation.create,
      payload: {'title': 'Manana'},
    );

    expect((await repository.pending()).single.id, item.id);

    await repository.markFailed(item.id, 'network');
    final failed = (await repository.pending()).single;
    expect(failed.status, SyncQueueStatus.failed);
    expect(failed.lastError, 'network');

    await repository.markPushed(item.id);
    expect(await repository.pending(), isEmpty);
  });

  test('accepts parent, caregiver and viewer family invitations', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final auth = LocalAuthRepository(store);
    final families = LocalFamilyRepository(store);

    final owner = await auth.registerAdult(
      displayName: 'Owner',
      email: 'owner@example.com',
      password: 'local',
    );
    final family = await families.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Casa',
    );

    for (final role in [
      FamilyMemberRole.parent,
      FamilyMemberRole.caregiver,
      FamilyMemberRole.viewer,
    ]) {
      final invitee = await auth.registerAdult(
        displayName: role.name,
        email: '${role.name}@example.com',
        password: 'local',
      );
      final invitation = await families.createAdultInvitation(
        familyId: family.metadata.id,
        email: invitee.email,
        role: role,
        invitedByUserId: owner.metadata.id,
      );

      final member = await families.acceptInvitation(
        invitationId: invitation.metadata.id,
        userId: invitee.metadata.id,
        userEmail: invitee.email,
      );

      expect(member.familyId, family.metadata.id);
      expect(member.userId, invitee.metadata.id);
      expect(member.role, role);
    }

    final members = await families.membersForFamily(family.metadata.id);
    expect(members, hasLength(4));
  });

  test('rejects invitations for a different email', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final auth = LocalAuthRepository(store);
    final families = LocalFamilyRepository(store);

    final owner = await auth.registerAdult(
      displayName: 'Owner',
      email: 'owner@example.com',
      password: 'local',
    );
    final family = await families.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Casa',
    );
    final invitation = await families.createAdultInvitation(
      familyId: family.metadata.id,
      email: 'invited@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: owner.metadata.id,
    );
    final other = await auth.registerAdult(
      displayName: 'Other',
      email: 'other@example.com',
      password: 'local',
    );

    expect(
      () => families.acceptInvitation(
        invitationId: invitation.metadata.id,
        userId: other.metadata.id,
        userEmail: other.email,
      ),
      throwsStateError,
    );
  });

  test('rejects expired invitations', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final auth = LocalAuthRepository(store);
    final families = LocalFamilyRepository(store);

    final owner = await auth.registerAdult(
      displayName: 'Owner',
      email: 'owner@example.com',
      password: 'local',
    );
    final family = await families.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Casa',
    );
    final invited = await auth.registerAdult(
      displayName: 'Invited',
      email: 'invited@example.com',
      password: 'local',
    );
    final invitation = await families.createAdultInvitation(
      familyId: family.metadata.id,
      email: invited.email,
      role: FamilyMemberRole.caregiver,
      invitedByUserId: owner.metadata.id,
    );
    final record = await store.get(
      LocalStoreCollections.adultInvitations,
      invitation.metadata.id,
    );
    await store.put(LocalStoreCollections.adultInvitations,
        invitation.metadata.id, {
      ...record!,
      'expires_at': DateTime.utc(2020, 1, 1).toIso8601String(),
    });

    expect(
      () => families.acceptInvitation(
        invitationId: invitation.metadata.id,
        userId: invited.metadata.id,
        userEmail: invited.email,
      ),
      throwsStateError,
    );
  });

  test('does not duplicate an accepted invitation or existing member', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final auth = LocalAuthRepository(store);
    final families = LocalFamilyRepository(store);

    final owner = await auth.registerAdult(
      displayName: 'Owner',
      email: 'owner@example.com',
      password: 'local',
    );
    final family = await families.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Casa',
    );
    final parent = await auth.registerAdult(
      displayName: 'Parent',
      email: 'parent@example.com',
      password: 'local',
    );
    final invitation = await families.createAdultInvitation(
      familyId: family.metadata.id,
      email: parent.email,
      role: FamilyMemberRole.parent,
      invitedByUserId: owner.metadata.id,
    );

    final first = await families.acceptInvitation(
      invitationId: invitation.metadata.id,
      userId: parent.metadata.id,
      userEmail: parent.email,
    );
    final second = await families.acceptInvitation(
      invitationId: invitation.metadata.id,
      userId: parent.metadata.id,
      userEmail: parent.email,
    );

    expect(second.metadata.id, first.metadata.id);
    expect(await families.membersForFamily(family.metadata.id), hasLength(2));

    final ownerInvitation = await families.createAdultInvitation(
      familyId: family.metadata.id,
      email: owner.email,
      role: FamilyMemberRole.caregiver,
      invitedByUserId: owner.metadata.id,
    );
    final ownerMember = await families.acceptInvitation(
      invitationId: ownerInvitation.metadata.id,
      userId: owner.metadata.id,
      userEmail: owner.email,
    );

    expect(ownerMember.role, FamilyMemberRole.owner);
    expect(await families.membersForFamily(family.metadata.id), hasLength(2));
  });

  test('rejects viewer administrative actions', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_local_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLocalStore(File('${directory.path}/habitar.json'));
    final auth = LocalAuthRepository(store);
    final families = LocalFamilyRepository(store);

    final owner = await auth.registerAdult(
      displayName: 'Owner',
      email: 'owner@example.com',
      password: 'local',
    );
    final family = await families.createFamily(
      ownerUserId: owner.metadata.id,
      name: 'Casa',
    );
    final viewer = await auth.registerAdult(
      displayName: 'Viewer',
      email: 'viewer@example.com',
      password: 'local',
    );
    final viewerInvitation = await families.createAdultInvitation(
      familyId: family.metadata.id,
      email: viewer.email,
      role: FamilyMemberRole.viewer,
      invitedByUserId: owner.metadata.id,
    );
    await families.acceptInvitation(
      invitationId: viewerInvitation.metadata.id,
      userId: viewer.metadata.id,
      userEmail: viewer.email,
    );

    expect(
      () => families.createAdultInvitation(
        familyId: family.metadata.id,
        email: 'another@example.com',
        role: FamilyMemberRole.caregiver,
        invitedByUserId: viewer.metadata.id,
      ),
      throwsStateError,
    );
  });
}
