import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:test/test.dart';

void main() {
  group('habitarFunctionalDate', () {
    // Paraguay uses permanent UTC-3 since October 2024 (Ley N. 7354).
    //
    // 03:30 UTC is the boundary that actually distinguishes -3 from -4:
    // under -3 it lands at 00:30 the same calendar day (still "today"),
    // under -4 it lands at 23:30 the *previous* day. 02:30 UTC would give
    // the same day under both offsets, so it can't catch a regression to
    // -4 — this test must use 03:30 UTC to be meaningful.
    test('03:30 UTC resolves to the same Asuncion day under UTC-3', () {
      final instant = DateTime.utc(2026, 1, 6, 3, 30);

      final result = habitarFunctionalDate(instant);

      expect(result, DateTime.utc(2026, 1, 6));
    });

    test('02:59 UTC is still the previous Asuncion day', () {
      final instant = DateTime.utc(2026, 1, 6, 2, 59);

      final result = habitarFunctionalDate(instant);

      expect(result, DateTime.utc(2026, 1, 5));
    });

    // Regression test for the bug reported against apps/mobile/test/
    // routine_real_data_flow_test.dart and routine_reminders_test.dart:
    // both failed only on the GitHub Actions runner (UTC), not on a
    // machine set to America/Asuncion, because every real call site
    // (routine_service.dart, routine_reminders.dart, the repositories)
    // calls habitarFunctionalDate() once to get "today" and then hands
    // that value to sameHabitarFunctionalDate/a repository method, which
    // calls habitarFunctionalDate() again internally. The old
    // implementation was not idempotent, and its non-idempotence was
    // masked whenever the process's own timezone happened to be
    // America/Asuncion — exactly the developer's machine, and exactly
    // not the CI runner.
    test('applying it twice gives the same day as applying it once, '
        'on any process timezone', () {
      final instant = DateTime.utc(2026, 1, 5, 23, 45);

      final once = habitarFunctionalDate(instant);
      final twice = habitarFunctionalDate(once);

      expect(twice, once);
    });

    test('is idempotent even when the second value carries a time '
        'component, as a scheduled reminder does', () {
      final today = habitarFunctionalDate(DateTime.utc(2026, 1, 5, 12));
      // A reminder scheduled for 09:00 local on that same functional day -
      // this is exactly the shape scheduleRoutineReminders() compares
      // against "today" in routine_reminders.dart.
      final scheduledAt =
          DateTime(today.year, today.month, today.day, 9);

      expect(sameHabitarFunctionalDate(scheduledAt, today), isTrue);
    });

    test('a genuine instant that is not already a functional date is '
        'still converted normally', () {
      // Not UTC-flagged, so it must not be mistaken for an already-resolved
      // functional date and skipped.
      final localNoon = DateTime(2026, 1, 5, 12);

      final result = habitarFunctionalDate(localNoon);

      expect(result.isUtc, isTrue);
    });
  });

  group('sameHabitarFunctionalDate', () {
    test('true for two instants on the same Asuncion day regardless of '
        'process timezone (simulated via explicit UTC/local inputs)', () {
      final morning = DateTime.utc(2026, 1, 5, 13); // 10:00 Asuncion
      final evening = DateTime.utc(2026, 1, 5, 23); // 20:00 Asuncion

      expect(sameHabitarFunctionalDate(morning, evening), isTrue);
    });

    test('false across the Asuncion midnight boundary', () {
      final beforeMidnight = DateTime.utc(2026, 1, 6, 2, 59);
      final afterMidnight = DateTime.utc(2026, 1, 6, 3, 30);

      expect(
        sameHabitarFunctionalDate(beforeMidnight, afterMidnight),
        isFalse,
      );
    });
  });
}
