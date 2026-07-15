import 'package:flutter_test/flutter_test.dart';

import 'package:habitar_mobile/src/app.dart';

void main() {
  testWidgets('shows adult registration as the first screen', (tester) async {
    await tester.pumpWidget(const HabitarMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Registro del adulto'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
