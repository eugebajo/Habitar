import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_data/data.dart';

import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/selected_profile.dart';

void main() {
  test('selected profile returns the real profile name, never a demo fallback',
      () async {
    final profileRepository = InMemoryProfileRepository();
    final nico = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentFamilyIdProvider.notifier).state = 'family-1';
    container.read(currentProfileIdProvider.notifier).state = nico.metadata.id;

    final selected = await container.read(selectedProfileProvider.future);

    expect(selected?.displayName, 'Nico');
    expect(selected?.displayName, isNot('Tomi'));
  });

  test('profile switch updates the selected profile provider', () async {
    final profileRepository = InMemoryProfileRepository();
    final nico = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final ana = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Ana',
      age: 10,
    );
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentFamilyIdProvider.notifier).state = 'family-1';
    container.read(currentProfileIdProvider.notifier).state = nico.metadata.id;

    final first = await container.read(selectedProfileProvider.future);
    container.read(currentProfileIdProvider.notifier).state = ana.metadata.id;
    container.invalidate(selectedProfileProvider);
    final second = await container.read(selectedProfileProvider.future);

    expect(first?.displayName, 'Nico');
    expect(second?.displayName, 'Ana');
  });
}
