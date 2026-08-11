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

      expect(result, DateTime(2026, 1, 6));
    });

    test('02:59 UTC is still the previous Asuncion day', () {
      final instant = DateTime.utc(2026, 1, 6, 2, 59);

      final result = habitarFunctionalDate(instant);

      expect(result, DateTime(2026, 1, 5));
    });
  });
}
