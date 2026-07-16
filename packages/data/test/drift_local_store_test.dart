import 'dart:io';

import 'package:habitar_data/data.dart';
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
}
