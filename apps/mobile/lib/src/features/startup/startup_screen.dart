import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../local_restore.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appRestoreProvider, (previous, next) {
      next.whenData((result) {
        final location = switch (result.destination) {
          AppRestoreDestination.onboarding => '/onboarding',
          AppRestoreDestination.register => '/register',
          AppRestoreDestination.profileSetup => '/profile',
          AppRestoreDestination.dashboard => '/dashboard',
        };
        context.go(location);
      });
    });

    final restoreState = ref.watch(appRestoreProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Habitar',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: HabitarSpacing.md),
                  if (restoreState.hasError)
                    const Text(
                        'No pudimos abrir tu espacio todavía. Podemos empezar de nuevo con calma.')
                  else
                    const Text(
                        'Preparando el lugar tranquilo de tu familia...'),
                  const SizedBox(height: HabitarSpacing.lg),
                  if (restoreState.isLoading)
                    const CircularProgressIndicator()
                  else
                    FilledButton(
                      onPressed: () => context.go('/onboarding'),
                      child: const Text('Continuar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
