import 'dart:io';

import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('stores and restores records from a SQLite file', () async {
    final directory =
        await Directory.systemTemp.createTemp('habitar_drift_store_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/habitar.sqlite');

    final firstStore = await DriftLocalStore.open(file);
    await firstStore.put(LocalStoreCollections.users, 'user-1', {
      'id': 'user-1',
      'email': 'adulto@example.com',
    });
    await firstStore.close();

    final secondStore = await DriftLocalStore.open(file);
    addTearDown(secondStore.close);

    final user = await secondStore.get(LocalStoreCollections.users, 'user-1');
    expect(user?['email'], 'adulto@example.com');
  });

  test('supports local repositories through the LocalStore contract', () async {
    final store = await DriftLocalStore.memory();
    addTearDown(store.close);

    final authRepository = LocalAuthRepository(store);
    final familyRepository = LocalFamilyRepository(store);

    final user = await authRepository.registerAdult(
      displayName: 'Adulto',
      email: 'adulto@example.com',
      password: 'not-stored',
    );
    await familyRepository.createFamily(
        ownerUserId: user.metadata.id, name: 'Casa');

    final restoredUser = await authRepository.currentUser();
    final restoredFamily =
        await familyRepository.currentFamily(user.metadata.id);

    expect(restoredUser?.email, 'adulto@example.com');
    expect(restoredFamily?.name, 'Casa');
  });

  test('stores several adult profiles for the same child profile', () async {
    final store = await DriftLocalStore.memory();
    addTearDown(store.close);

    final repository = LocalAdultProfileRepository(store);

    await repository.createAdultProfile(
      familyId: 'family-1',
      profileId: 'child-1',
      displayName: 'Mamá',
      kind: AdultProfileKind.parent,
      email: 'mama@example.com',
    );
    await repository.createAdultProfile(
      familyId: 'family-1',
      profileId: 'child-1',
      displayName: 'Psicóloga',
      kind: AdultProfileKind.professional,
      email: 'psico@example.com',
    );

    final adults = await repository.adultProfilesForProfile('child-1');

    expect(adults.map((profile) => profile.displayName),
        containsAll(['Mamá', 'Psicóloga']));
    expect(adults, hasLength(2));
  });

  test('stores routine schedule in local repositories', () async {
    final store = await DriftLocalStore.memory();
    addTearDown(store.close);

    final repository = LocalRoutineRepository(store);

    await repository.createRoutine(
      profileId: 'child-1',
      title: 'Prepararse para salir',
      stepTitles: [
        'Guardar la botella',
        'Ponerse los zapatos',
        'Tomar la mochila'
      ],
      weekdays: [1, 3, 5],
      scheduledHour: 7,
      scheduledMinute: 30,
      estimatedDurationMinutes: 20,
      leadReminderMinutes: 15,
      repeatPolicy: RoutineRepeatPolicy.weekdays,
      responsibleAdultProfileId: 'adult-1',
      contextLabel: 'Casa',
      minimumVersion: 'Guardar mochila',
      benefitDescription: '10 minutos de juego',
      maxReminderCount: 3,
      reminderIntervalMinutes: 7,
      vibrationEnabled: false,
      soundEnabled: true,
      silentNotification: false,
      canPostpone: false,
      canRequestHelp: true,
    );

    final routines = await repository.routinesForProfile('child-1');
    final routine = routines.single;

    expect(routine.scheduledTimeLabel, '07:30');
    expect(routine.weekdays, [1, 3, 5]);
    expect(routine.estimatedDurationMinutes, 20);
    expect(routine.leadReminderMinutes, 15);
    expect(routine.repeatPolicy, RoutineRepeatPolicy.weekdays);
    expect(routine.responsibleAdultProfileId, 'adult-1');
    expect(routine.contextLabel, 'Casa');
    expect(routine.minimumVersion, 'Guardar mochila');
    expect(routine.benefitDescription, '10 minutos de juego');
    expect(routine.maxReminderCount, 3);
    expect(routine.reminderIntervalMinutes, 7);
    expect(routine.vibrationEnabled, isFalse);
    expect(routine.soundEnabled, isTrue);
    expect(routine.silentNotification, isFalse);
    expect(routine.canPostpone, isFalse);
    expect(routine.canRequestHelp, isTrue);
  });
}
