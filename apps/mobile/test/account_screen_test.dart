import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';

import 'package:habitar_mobile/src/features/account/account_screen.dart';
import 'package:habitar_mobile/src/dependencies.dart';

void main() {
  testWidgets('Account screen shows account actions for owner', (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(displayName: 'Owner', email: 'owner@example.com', password: 'pass');
    final familyRepo = InMemoryFamilyRepository();
    final family = await familyRepo.createFamily(ownerUserId: user.metadata.id, name: 'Test Family');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          familyRepositoryProvider.overrideWithValue(familyRepo),
          currentFamilyIdProvider.overrideWithValue(family.metadata.id),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Eliminar mi cuenta'), findsOneWidget);
  });
}
