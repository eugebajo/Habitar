import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:habitar_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adult can start the registration flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Registro del adulto'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
