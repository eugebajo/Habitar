import 'package:habitar_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HabitActivationPolicy', () {
    test('allows up to two new active habits for a child profile', () {
      final policy = HabitActivationPolicy();

      final decision = policy.evaluate(
        profileKind: ProfileKind.child,
        activeHabits: [_habit('1'), _habit('2')],
      );

      expect(decision.isAllowed, isTrue);
    });

    test('requires override above two new active habits for a child profile', () {
      final policy = HabitActivationPolicy();

      final decision = policy.evaluate(
        profileKind: ProfileKind.child,
        activeHabits: [_habit('1'), _habit('2'), _habit('3')],
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.warning, contains('sobrecarga'));
    });

    test('allows up to three new active habits for a teen profile', () {
      final policy = HabitActivationPolicy();

      final decision = policy.evaluate(
        profileKind: ProfileKind.teen,
        activeHabits: [_habit('1'), _habit('2'), _habit('3')],
      );

      expect(decision.isAllowed, isTrue);
    });
  });
}

Habit _habit(String id) {
  final now = DateTime(2026, 1, 1);
  return Habit(
    metadata: EntityMetadata(id: id, createdAt: now, updatedAt: now, ownerId: 'adult-1'),
    profileId: 'profile-1',
    title: 'Habito $id',
    status: HabitStatus.newHabit,
  );
}
