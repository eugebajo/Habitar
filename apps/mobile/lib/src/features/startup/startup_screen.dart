import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(passwordRecoveryActiveProvider, (previous, next) {
      if (next) {
        context.go('/reset-password');
      }
    });

    ref.listen(appRestoreProvider, (previous, next) {
      next.whenData((result) async {
        if (ref.read(passwordRecoveryActiveProvider)) {
          _debugLog('ROUTER DESTINATION: /reset-password');
          context.go('/reset-password');
          return;
        }
        if (result.departureNotices.isNotEmpty) {
          final navigatedAway =
              await _showDepartureNotices(context, ref, result.departureNotices);
          if (navigatedAway) return;
          if (!context.mounted) return;
        }
        // Etapa 3: registra/refresca el token en cada arranque con sesión
        // activa, no solo en el momento del login - cubre con mucho el
        // caso más común, reabrir la app con una sesión ya iniciada de
        // antes. No se espera - best-effort, nunca debe atrasar la
        // navegación.
        final userId = result.userId;
        if (userId != null) {
          unawaited(ref
              .read(pushNotificationServiceProvider)
              .registerCurrentDevice(userId));
        }
        final location = switch (result.destination) {
          AppRestoreDestination.onboarding => '/onboarding',
          AppRestoreDestination.register => '/register',
          AppRestoreDestination.invitation => '/invitation',
          AppRestoreDestination.profileSetup => '/profile',
          AppRestoreDestination.dashboard => '/dashboard',
        };
        _debugLog('ROUTER DESTINATION: $location');
        context.go(location);
      });
    });

    final recoveryActive = ref.watch(passwordRecoveryActiveProvider);
    if (recoveryActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/reset-password');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

/// Shows each pending [FamilyDepartureNotice] for the signed-in adult, one
/// dialog at a time - a family they belonged to was deleted by its owner
/// (see delete_family in supabase/migrations/0014_family_deletion.sql)
/// while they weren't using the app. Deliberately carries no data about a
/// child, only the family's name and that it's gone. Each notice is
/// dismissed (its row deleted) right after being shown once, regardless of
/// which button was tapped - never shown twice.
///
/// Returns true if the adult chose to create a new family from here, in
/// which case this already navigated to /profile and the caller must not
/// navigate anywhere else.
Future<bool> _showDepartureNotices(
  BuildContext context,
  WidgetRef ref,
  List<FamilyDepartureNotice> notices,
) async {
  final authRepo = ref.read(authRepositoryProvider);
  final user = await authRepo.currentUser();
  if (user == null) return false;

  for (final notice in notices) {
    if (!context.mounted) return false;
    final createNew = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tu espacio familiar ya no está'),
        content: Text(
          'El espacio familiar "${notice.familyName}" al que pertenecías '
          'fue eliminado. Podés crear un nuevo espacio cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Crear un nuevo espacio'),
          ),
        ],
      ),
    );

    // Best-effort: shown once is enough - if this delete fails, worst case
    // the same notice shows again next launch, never a data-loss risk.
    try {
      await ref.read(familyRepositoryProvider).dismissDepartureNotice(
            noticeId: notice.id,
            userId: user.metadata.id,
          );
    } catch (_) {
      // ignore, see comment above.
    }

    if (createNew == true) {
      if (!context.mounted) return false;
      return _createNewFamilyAndContinue(context, ref, user);
    }
  }
  return false;
}

/// Prompts for a new family name and creates it directly for the already
/// signed-in [user] - unlike AdultRegistrationScreen (/register), this
/// never signs up a new account, just gives an adult who still has a
/// session but no family a working way to start one.
Future<bool> _createNewFamilyAndContinue(
  BuildContext context,
  WidgetRef ref,
  User user,
) async {
  final controller = TextEditingController();
  final familyName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nombrá tu nuevo espacio'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre de la familia'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Crear'),
        ),
      ],
    ),
  );
  if (familyName == null || familyName.isEmpty) return false;
  if (!context.mounted) return false;

  final family = await ref.read(familyRepositoryProvider).createFamily(
        ownerUserId: user.metadata.id,
        name: familyName,
      );
  ref.read(currentFamilyIdProvider.notifier).state = family.metadata.id;
  if (!context.mounted) return false;
  context.go('/profile');
  return true;
}

void _debugLog(String message) {
  assert(() {
    // Development-only diagnostics. Do not log passwords, tokens or secrets.
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
