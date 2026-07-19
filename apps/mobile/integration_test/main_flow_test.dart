import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:habitar_mobile/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adult can start the registration flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitarMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Crear mi espacio'), findsOneWidget);

    await tester.tap(find.text('Crear mi espacio'));
    await tester.pumpAndSettle();

    expect(find.text('Contame quien sostiene este espacio.'), findsOneWidget);
    expect(find.text('Seguir con mi familia'), findsOneWidget);
  });
}
