import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/routine_setup/routine_setup_screen.dart';
import 'package:habitar_mobile/src/platform/routine_save_diagnostics.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  test('routine save diagnostic code uses PostgREST code', () {
    final error = supabase.PostgrestException(
      message: 'new row violates row-level security policy',
      code: '42501',
      details: 'RLS rejected insert',
      hint: null,
    );

    expect(
      routineSaveDiagnosticCode(error),
      'HABITAR_ROUTINE_SAVE_42501',
    );
  });

  testWidgets('save button ignores a second tap while submitting',
      (tester) async {
    final repository = _BlockingRoutineRepository();
    await tester.pumpWidget(
      _testApp(
        routineRepository: repository,
        currentProfileId: 'profile-nico',
      ),
    );
    await tester.pumpAndSettle();

    await _tapSaveButton(tester);
    await tester.pump();
    await tester.tap(find.text('Guardando...'), warnIfMissed: false);
    await tester.pump();

    expect(repository.createCalls, 1);

    repository.complete();
    await tester.pumpAndSettle();

    expect(find.text('Rutinas'), findsOneWidget);
  });

  testWidgets('missing profile routes away instead of sending empty id',
      (tester) async {
    final repository = _BlockingRoutineRepository();
    await tester.pumpWidget(
      _testApp(
        routineRepository: repository,
        currentProfileId: null,
      ),
    );
    await tester.pumpAndSettle();

    await _tapSaveButton(tester);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 0);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('PostgREST errors show a safe diagnostic code in debug',
      (tester) async {
    final repository = _ThrowingRoutineRepository(
      supabase.PostgrestException(
        message: 'insert or update on table violates foreign key constraint',
        code: '23503',
        details: 'routine profile does not exist',
        hint: null,
      ),
    );
    await tester.pumpWidget(
      _testApp(
        routineRepository: repository,
        currentProfileId: 'profile-nico',
      ),
    );
    await tester.pumpAndSettle();

    await _tapSaveButton(tester);
    await tester.pump();

    expect(find.textContaining('No pudimos guardar la rutina'), findsOneWidget);
    expect(find.textContaining('HABITAR_ROUTINE_SAVE_23503'), findsOneWidget);
  });
}

Future<void> _tapSaveButton(WidgetTester tester) async {
  final button = find.text('Guardar rutina');
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 12,
  );
  await tester.tap(button);
}

Widget _testApp({
  required RoutineRepository routineRepository,
  required String? currentProfileId,
}) {
  final router = GoRouter(
    initialLocation: '/routine/create',
    routes: [
      GoRoute(
        path: '/routine/create',
        builder: (context, state) => const RoutineSetupScreen(),
      ),
      GoRoute(
        path: '/routines',
        builder: (context, state) => const Scaffold(body: Text('Rutinas')),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(body: Text('Perfil')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      routineRepositoryProvider.overrideWithValue(routineRepository),
      currentProfileIdProvider.overrideWith((ref) => currentProfileId),
      profileRepositoryProvider.overrideWithValue(InMemoryProfileRepository()),
      reminderSchedulerProvider.overrideWithValue(InMemoryReminderScheduler()),
    ],
    child: MaterialApp.router(
      theme: buildHabitarTheme(),
      routerConfig: router,
    ),
  );
}

class _BlockingRoutineRepository implements RoutineRepository {
  final _completer = Completer<Routine>();
  int createCalls = 0;
  Routine? _routine;

  void complete() {
    final now = DateTime(2026, 1, 1);
    _routine = Routine(
      metadata: EntityMetadata(
        id: 'routine-1',
        createdAt: now,
        updatedAt: now,
        ownerId: 'user-1',
      ),
      profileId: 'profile-nico',
      title: 'Prepararse para salir',
      stepIds: const ['step-1', 'step-2', 'step-3'],
    );
    _completer.complete(_routine);
  }

  @override
  Future<Routine> createRoutine({
    required String profileId,
    required String title,
    required List<String> stepTitles,
    List<int> weekdays = const [],
    int? scheduledHour,
    int? scheduledMinute,
    int? estimatedDurationMinutes,
    int leadReminderMinutes = 10,
    RoutineRepeatPolicy repeatPolicy = RoutineRepeatPolicy.weekly,
    String? responsibleAdultProfileId,
    String? contextLabel,
    String? minimumVersion,
    String? benefitDescription,
    int maxReminderCount = 2,
    int reminderIntervalMinutes = 5,
    bool vibrationEnabled = true,
    bool soundEnabled = false,
    bool silentNotification = false,
    bool canPostpone = true,
    bool canRequestHelp = true,
  }) {
    createCalls += 1;
    return _completer.future;
  }

  @override
  Future<List<RoutineStep>> stepsForRoutine(String routineId) async {
    final now = DateTime(2026, 1, 1);
    return [
      for (var index = 0; index < 3; index += 1)
        RoutineStep(
          metadata: EntityMetadata(
            id: 'step-${index + 1}',
            createdAt: now,
            updatedAt: now,
            ownerId: 'user-1',
          ),
          routineId: routineId,
          title: 'Paso ${index + 1}',
          order: index + 1,
          estimatedMinutes: 5,
        ),
    ];
  }

  @override
  Future<Routine?> routineById(String routineId) async => _routine;

  @override
  Future<List<Routine>> routinesForProfile(String profileId) async =>
      _routine == null ? const [] : [_routine!];

  @override
  Future<Routine> updateRoutine({
    required Routine routine,
    required List<String> stepTitles,
  }) async =>
      routine;

  @override
  Future<Routine> duplicateRoutine(String routineId) async => _routine!;

  @override
  Future<Routine> updateRoutineStatus(
          String routineId, EntityStatus status) async =>
      _routine!;
}

class _ThrowingRoutineRepository extends _BlockingRoutineRepository {
  _ThrowingRoutineRepository(this.error);

  final Object error;

  @override
  Future<Routine> createRoutine({
    required String profileId,
    required String title,
    required List<String> stepTitles,
    List<int> weekdays = const [],
    int? scheduledHour,
    int? scheduledMinute,
    int? estimatedDurationMinutes,
    int leadReminderMinutes = 10,
    RoutineRepeatPolicy repeatPolicy = RoutineRepeatPolicy.weekly,
    String? responsibleAdultProfileId,
    String? contextLabel,
    String? minimumVersion,
    String? benefitDescription,
    int maxReminderCount = 2,
    int reminderIntervalMinutes = 5,
    bool vibrationEnabled = true,
    bool soundEnabled = false,
    bool silentNotification = false,
    bool canPostpone = true,
    bool canRequestHelp = true,
  }) async {
    throw error;
  }
}
