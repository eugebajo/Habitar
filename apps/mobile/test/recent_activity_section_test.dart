import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/features/family_dashboard/activity_feed_section.dart';

FamilyActivityEvent _event({
  required String id,
  required String profileDisplayName,
  required String routineTitle,
  required DateTime createdAt,
}) {
  return FamilyActivityEvent(
    metadata: EntityMetadata(
      id: id,
      createdAt: createdAt,
      updatedAt: createdAt,
      ownerId: 'family-a',
    ),
    familyId: 'family-a',
    profileId: 'profile-nico',
    routineId: 'routine-1',
    sessionId: 'session-$id',
    kind: 'routine_completed',
    profileDisplayName: profileDisplayName,
    routineTitle: routineTitle,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: buildHabitarTheme(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('shows an inviting empty state, not an error, with no events',
      (tester) async {
    await tester.pumpWidget(_wrap(const RecentActivitySection(events: [])));

    expect(find.text('Todavía no hay actividad'), findsOneWidget);
    expect(find.textContaining('rror'), findsNothing);
  });

  testWidgets('shows each event with a warm phrasing and a relative time',
      (tester) async {
    final now = DateTime(2026, 8, 28, 12, 0);
    final events = [
      _event(
        id: '1',
        profileDisplayName: 'Nico',
        routineTitle: 'Prepararse para la escuela',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];

    await tester.pumpWidget(_wrap(RecentActivitySection(events: events)));

    expect(find.textContaining('Nico'), findsOneWidget);
    expect(find.textContaining('Prepararse para la escuela'), findsOneWidget);
  });

  testWidgets('fits at 320px with a long name and a long routine title',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 28, 12, 0);
    final events = [
      _event(
        id: '1',
        profileDisplayName: 'Alejandra Guadalupe',
        routineTitle:
            'Prepararse para la escuela con mochila, buzo y merienda completa',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      _event(
        id: '2',
        profileDisplayName: 'Nico',
        routineTitle: 'Rutina de la noche',
        createdAt: now.subtract(const Duration(days: 1, hours: -2)),
      ),
    ];

    await tester.pumpWidget(_wrap(RecentActivitySection(events: events)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('formatRelativeActivityTime', () {
    final now = DateTime(2026, 8, 28, 19, 30);

    test('just now for anything under a minute', () {
      final when = now.subtract(const Duration(seconds: 30));
      expect(formatRelativeActivityTime(when, now: now), 'justo ahora');
    });

    test('minutes ago, singular and plural', () {
      expect(
        formatRelativeActivityTime(now.subtract(const Duration(minutes: 1)),
            now: now),
        'hace 1 minuto',
      );
      expect(
        formatRelativeActivityTime(now.subtract(const Duration(minutes: 10)),
            now: now),
        'hace 10 minutos',
      );
    });

    test('today, past the hour mark', () {
      final when = DateTime(2026, 8, 28, 8, 5);
      expect(
        formatRelativeActivityTime(when, now: now),
        'hoy a las 08:05',
      );
    });

    test('yesterday', () {
      final when = DateTime(2026, 8, 27, 19, 30);
      expect(
        formatRelativeActivityTime(when, now: now),
        'ayer a las 19:30',
      );
    });

    test('older than yesterday, same year', () {
      final when = DateTime(2026, 8, 1, 9, 0);
      expect(
        formatRelativeActivityTime(when, now: now),
        '1 de agosto a las 09:00',
      );
    });

    test('older than yesterday, different year', () {
      final when = DateTime(2025, 12, 24, 18, 0);
      expect(
        formatRelativeActivityTime(when, now: now),
        '24 de diciembre de 2025 a las 18:00',
      );
    });
  });
}
