import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habitar_mobile/src/app.dart';

void main() {
  testWidgets('shows onboarding as the first screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitarMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Habitar'), findsOneWidget);
    expect(find.text('Crear acompanamiento'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });
}
