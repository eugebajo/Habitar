import 'dart:io';

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
}
