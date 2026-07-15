import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_domain/domain.dart';

void main() {
  test('domain policy remains available to the Flutter app without UI dependencies', () {
    const policy = HabitActivationPolicy();

    expect(policy.recommendedLimit(ProfileKind.child), 2);
    expect(policy.recommendedLimit(ProfileKind.teen), 3);
  });
}
