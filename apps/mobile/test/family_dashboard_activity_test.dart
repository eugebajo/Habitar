// Confirms the adult dashboard actually wires up "Actividad reciente" end to
// end (through FamilyDashboardScreen._loadDashboard and
// familyActivityEventRepositoryProvider), not just that the section widget
// renders in isolation (see recent_activity_section_test.dart for that).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/family_dashboard/family_dashboard_screen.dart';

void main() {
  testWidgets('dashboard shows a real event coming from the repository',
      (tester) async {
    final familyRepository = InMemoryFamilyRepository();
    final profileRepository = InMemoryProfileRepository();
    final activityEvents = InMemoryFamilyActivityEventRepository();

    final family = await familyRepository.createFamily(
        ownerUserId: 'adult-owner', name: 'Familia de prueba');
    final profile = await profileRepository.createChildProfile(
        familyId: family.metadata.id, displayName: 'Nico', age: 9);

    final now = DateTime.now();
    activityEvents.events.add(FamilyActivityEvent(
      metadata: EntityMetadata(
        id: 'event-1',
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        ownerId: family.metadata.id,
      ),
      familyId: family.metadata.id,
      profileId: profile.metadata.id,
      routineId: 'routine-1',
      sessionId: 'session-1',
      kind: 'routine_completed',
      profileDisplayName: 'Nico',
      routineTitle: 'Prepararse para la escuela',
    ));

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const FamilyDashboardScreen(),
        ),
        GoRoute(
          path: '/profiles',
          builder: (context, state) => const Scaffold(body: Text('Perfiles')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyRepositoryProvider.overrideWithValue(familyRepository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
          familyActivityEventRepositoryProvider
              .overrideWithValue(activityEvents),
          currentFamilyIdProvider.overrideWith((ref) => family.metadata.id),
          currentProfileIdProvider.overrideWith((ref) => profile.metadata.id),
          currentProfileKindProvider.overrideWith((ref) => ProfileKind.child),
        ],
        child: MaterialApp.router(
          theme: buildHabitarTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Actividad reciente'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();

    expect(find.text('Actividad reciente'), findsOneWidget);
    expect(find.textContaining('Nico'), findsWidgets);
    expect(find.textContaining('Prepararse para la escuela'), findsOneWidget);
    expect(find.textContaining('hace 15 minutos'), findsOneWidget);
    expect(find.text('Todavía no hay actividad'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard shows the inviting empty state with no events',
      (tester) async {
    final familyRepository = InMemoryFamilyRepository();
    final profileRepository = InMemoryProfileRepository();

    final family = await familyRepository.createFamily(
        ownerUserId: 'adult-owner', name: 'Familia de prueba');
    final profile = await profileRepository.createChildProfile(
        familyId: family.metadata.id, displayName: 'Nico', age: 9);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const FamilyDashboardScreen(),
        ),
        GoRoute(
          path: '/profiles',
          builder: (context, state) => const Scaffold(body: Text('Perfiles')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyRepositoryProvider.overrideWithValue(familyRepository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
          currentFamilyIdProvider.overrideWith((ref) => family.metadata.id),
          currentProfileIdProvider.overrideWith((ref) => profile.metadata.id),
          currentProfileKindProvider.overrideWith((ref) => ProfileKind.child),
        ],
        child: MaterialApp.router(
          theme: buildHabitarTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Todavía no hay actividad'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay actividad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
