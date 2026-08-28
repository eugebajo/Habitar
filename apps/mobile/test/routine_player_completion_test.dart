import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/routine_player/routine_player_screen.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

void main() {
  testWidgets(
      'a completeSession failure shows a friendly message instead of a '
      'crash, and stays retryable', (tester) async {
    final routine = Routine(
      metadata: EntityMetadata(
        id: 'routine-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: 'profile-1',
      ),
      profileId: 'profile-1',
      title: 'Rutina de prueba',
      stepIds: const ['step-1'],
    );
    final step = RoutineStep(
      metadata: EntityMetadata(
        id: 'step-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: 'profile-1',
      ),
      routineId: 'routine-1',
      title: 'Unico paso',
      order: 1,
    );
    final session = RoutineSession(
      id: 'session-1',
      routine: routine,
      steps: [step],
      activeStepIndex: 0,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final sessionRepository = _FlakyThenOkSessionRepository(session);

    final router = GoRouter(
      initialLocation: '/routine/player',
      routes: [
        GoRoute(
          path: '/routine/player',
          builder: (context, state) => const RoutinePlayerScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routineSessionRepositoryProvider
              .overrideWithValue(sessionRepository),
          currentProfileIdProvider.overrideWith((ref) => 'profile-1'),
          currentRoutineSessionIdProvider.overrideWith((ref) => 'session-1'),
        ],
        child: MaterialApp.router(
          theme: buildHabitarTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unico paso'), findsOneWidget);

    // First tap: the RPC fails. The child must see a warm message, not a
    // crash, and the routine must still be shown as not-yet-done.
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No pudimos guardar eso. Probá de nuevo en un momento.'),
        findsOneWidget);
    expect(find.text('Unico paso'), findsOneWidget);
    expect(sessionRepository.completeSessionCalls, 1);

    // Second tap (retry): same session, now succeeds.
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sessionRepository.completeSessionCalls, 2);
    expect(find.text('¡Lo hiciste!'), findsOneWidget);
  });
}

class _FlakyThenOkSessionRepository implements RoutineSessionRepository {
  _FlakyThenOkSessionRepository(this._initial);

  final RoutineSession _initial;
  var completeSessionCalls = 0;
  var shouldFail = true;

  @override
  Future<RoutineSession> completeSession(RoutineSession session) async {
    completeSessionCalls += 1;
    if (shouldFail) {
      shouldFail = false;
      throw StateError('RPC_FAILED');
    }
    return session;
  }

  @override
  Future<void> save(RoutineSession session) async {}

  @override
  Future<RoutineSession?> activeSessionForProfile(String profileId) async =>
      _initial;

  @override
  Future<RoutineSession?> activeSessionForRoutineToday({
    required String routineId,
    required DateTime localDate,
  }) async =>
      null;

  @override
  Future<List<RoutineSession>> sessionsForProfileDate({
    required String profileId,
    required DateTime localDate,
  }) async =>
      const [];

  @override
  Future<RoutineSession?> latestSessionForRoutineDate({
    required String routineId,
    required DateTime localDate,
  }) async =>
      null;

  @override
  Future<RoutineSession?> byId(String sessionId) async => _initial;
}
