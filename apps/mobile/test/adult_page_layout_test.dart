import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_mobile/src/components/adult_shell.dart';

void main() {
  testWidgets(
      'progress title remains visible on narrow screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/progress',
      routes: [
        GoRoute(
          path: '/progress',
          builder: (context, state) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
            ),
            child: AdultPage(
              title: 'Progreso semanal',
              action: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ver logros'),
              ),
              child: const EmptyState(
                icon: Icons.insights_rounded,
                title: 'Se observó un avance',
                message: 'El resumen ayuda a decidir el próximo apoyo.',
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      theme: buildHabitarTheme(),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Progreso semanal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
