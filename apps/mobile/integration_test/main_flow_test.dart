import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:habitar_mobile/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adult can start the registration flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitarMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Crear acompanamiento'), findsOneWidget);

    await tester.tap(find.text('Crear acompanamiento'));
    await tester.pumpAndSettle();

    expect(find.text('Registro del adulto'), findsOneWidget);
    expect(find.text('Crear acompanamiento familiar'), findsOneWidget);
  });
}
