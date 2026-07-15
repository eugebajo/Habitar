import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('HabitEngine', () {
    test('requires adult override when child profile would exceed two new habits', () {
      final engine = HabitEngine();
      final plan = engine.evaluateActivation(
        habit: _habit('3'),
        profileKind: ProfileKind.child,
        activeHabits: [_habit('1'), _habit('2')],
      );

      expect(plan.decision.isAllowed, isFalse);
      expect(plan.recommendedLimit, 2);
    });

    test('summarizes weekly progress without streak language', () {
      final engine = HabitEngine();
      final summary = engine.summarizeWeek(
        habitId: '1',
        entries: [
          HabitProgressEntry(habitId: '1', recordedAt: DateTime(2026), completedMinimumVersion: true, helpLevel: 1, ease: 4),
          HabitProgressEntry(habitId: '1', recordedAt: DateTime(2026, 1, 2), completedMinimumVersion: true, helpLevel: 2, ease: 3),
        ],
      );

      expect(summary.minimumVersionCompletions, 2);
      expect(summary.supportiveInsight, isNot(contains('racha')));
    });
  });
}

Habit _habit(String id) {
  final now = DateTime(2026);
  return Habit(
    metadata: EntityMetadata(id: id, createdAt: now, updatedAt: now, ownerId: 'profile-1'),
    profileId: 'profile-1',
    title: 'Habito $id',
    status: HabitStatus.newHabit,
    minimumVersion: 'Version minima $id',
  );
}
