import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habitar_mobile/src/app.dart';

void main() {
  testWidgets('shows onboarding entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitarMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Habitos posibles para familias reales.'), findsOneWidget);
    expect(find.text('Crear mi espacio'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
  });
}
