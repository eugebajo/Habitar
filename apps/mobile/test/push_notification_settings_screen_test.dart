// Etapa 3 (notificaciones push), Parte 4: la pantalla de preferencias -
// carga lo ya guardado, el interruptor (HabitarToggle) prende/apaga, el
// horario silencioso se guarda y se puede quitar, y no deja guardar un
// horario a medias.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/account/push_notification_settings_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required InMemoryAuthRepository auth,
    required InMemoryPushNotificationPreferenceRepository preferences,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          pushNotificationPreferenceRepositoryProvider
              .overrideWithValue(preferences),
        ],
        child: MaterialApp(
          theme: buildHabitarTheme(),
          home: const PushNotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin preferencias guardadas, arranca con avisos activados',
      (tester) async {
    final auth = InMemoryAuthRepository();
    await auth.registerAdult(
        displayName: 'Ana', email: 'ana@example.com', password: 'secret123');

    await pumpScreen(
      tester,
      auth: auth,
      preferences: InMemoryPushNotificationPreferenceRepository(),
    );

    final toggle = tester.widget<HabitarToggle>(find.byType(HabitarToggle));
    expect(toggle.value, isTrue);
    expect(find.text('Horario silencioso'), findsOneWidget);
  });

  testWidgets('carga push_enabled = false ya guardado', (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
        displayName: 'Ana', email: 'ana@example.com', password: 'secret123');
    final preferences = InMemoryPushNotificationPreferenceRepository();
    await preferences.save(PushNotificationPreference(
      userId: user.metadata.id,
      pushEnabled: false,
    ));

    await pumpScreen(tester, auth: auth, preferences: preferences);

    final toggle = tester.widget<HabitarToggle>(find.byType(HabitarToggle));
    expect(toggle.value, isFalse);
    // Con avisos apagados, la sección de horario silencioso ni se muestra.
    expect(find.text('Horario silencioso'), findsNothing);
  });

  testWidgets('tocar el interruptor y guardar persiste push_enabled',
      (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
        displayName: 'Ana', email: 'ana@example.com', password: 'secret123');
    final preferences = InMemoryPushNotificationPreferenceRepository();

    await pumpScreen(tester, auth: auth, preferences: preferences);

    await tester.tap(find.byType(HabitarToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias guardadas'), findsOneWidget);
    final saved = await preferences.forUser(user.metadata.id);
    expect(saved?.pushEnabled, isFalse);
  });

  testWidgets('elegir las dos horas del horario silencioso y guardarlas',
      (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
        displayName: 'Ana', email: 'ana@example.com', password: 'secret123');
    final preferences = InMemoryPushNotificationPreferenceRepository();

    await pumpScreen(tester, auth: auth, preferences: preferences);

    await tester.tap(find.text('Desde'));
    await tester.pumpAndSettle();
    // El time picker de Material arranca en 21:00 (default de esta
    // pantalla) - confirmar tal cual alcanza para este test.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hasta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final saved = await preferences.forUser(user.metadata.id);
    expect(saved?.hasQuietHours, isTrue);
  });

  testWidgets('un horario a medias no se guarda, avisa en vez de eso',
      (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
        displayName: 'Ana', email: 'ana@example.com', password: 'secret123');
    final preferences = InMemoryPushNotificationPreferenceRepository();

    await pumpScreen(tester, auth: auth, preferences: preferences);

    await tester.tap(find.text('Desde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // 'Hasta' se deja sin tocar a propósito.

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Elegí las dos horas del horario silencioso, o ninguna.'),
      findsOneWidget,
    );
    final saved = await preferences.forUser(user.metadata.id);
    expect(saved, isNull);
  });
}
