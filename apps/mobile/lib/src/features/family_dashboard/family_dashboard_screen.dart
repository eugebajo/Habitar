import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProfile = ref.watch(currentProfileIdProvider) != null;
    final hasRoutineWaiting =
        ref.watch(currentRoutineSessionIdProvider) != null;

    return Scaffold(
      body: HabitarPage(
        maxWidth: 760,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Cerrar sesion',
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
            ),
          ),
          Text('Hoy', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: HabitarSpacing.lg),
          HabitarMoment(
            eyebrow: 'Respiremos',
            title: hasRoutineWaiting
                ? 'Hay un pequeno camino preparado.'
                : 'No tienes que resolver todo ahora.',
            body: hasRoutineWaiting
                ? 'Habitar puede acompanar el proximo paso sin apurar, sin rachas y sin castigos.'
                : 'Elige una sola cosa importante para hoy. Lo demas puede esperar.',
            color: HabitarColors.sunlit,
            trailing: FilledButton(
              onPressed: () => context.go('/profiles'),
              child: const Text('Elegir quien empieza'),
            ),
          ),
          const SizedBox(height: HabitarSpacing.lg),
          _TodayAction(
            title: 'Preparar una rutina',
            body: 'Tres pasos claros para que el dia tenga menos friccion.',
            action: hasActiveProfile ? 'Preparar' : 'Elegir perfil',
            color: HabitarColors.surfaceMist,
            onTap: () =>
                context.go(hasActiveProfile ? '/routine/create' : '/profiles'),
          ),
          _TodayAction(
            title: 'Cuidar un habito',
            body:
                'Una version minima, pequena y posible. Nada de exigir de mas.',
            action: hasActiveProfile ? 'Acompanarlo' : 'Elegir perfil',
            color: HabitarColors.surfaceWarm,
            onTap: () => context.go(hasActiveProfile ? '/habits' : '/profiles'),
          ),
          _TodayAction(
            title: 'Mirar como esta',
            body: 'Un check-in suave para pedir silencio, movimiento o ayuda.',
            action: hasActiveProfile ? 'Abrir' : 'Elegir perfil',
            color: HabitarColors.softBlue.withValues(alpha: 0.2),
            onTap: () =>
                context.go(hasActiveProfile ? '/wellbeing' : '/profiles'),
          ),
          _TodayAction(
            title: 'Leer juntos',
            body:
                'Cuentos breves para cerrar el dia con conversacion, no con tarea.',
            action: hasActiveProfile ? 'Elegir cuento' : 'Elegir perfil',
            color: HabitarColors.lavender.withValues(alpha: 0.25),
            onTap: () =>
                context.go(hasActiveProfile ? '/stories' : '/profiles'),
          ),
          const SizedBox(height: HabitarSpacing.md),
          TextButton(
            onPressed: () => context.go('/notifications'),
            child: const Text('Ajustar recordatorios con calma'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionServiceProvider).signOut();
    ref.read(currentFamilyIdProvider.notifier).state = null;
    ref.read(currentProfileIdProvider.notifier).state = null;
    ref.read(currentProfileKindProvider.notifier).state = null;
    ref.read(currentRoutineSessionIdProvider.notifier).state = null;
    ref.invalidate(appRestoreProvider);
    if (context.mounted) {
      context.go('/onboarding');
    }
  }
}

class _TodayAction extends StatelessWidget {
  const _TodayAction({
    required this.title,
    required this.body,
    required this.action,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String body;
  final String action;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HabitarConversationCard(
      title: title,
      body: body,
      color: color,
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: onTap,
          child: Text(action),
        ),
      ),
    );
  }
}
