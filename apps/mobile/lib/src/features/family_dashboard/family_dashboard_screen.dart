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
    final hasLocalStore = ref.watch(localStoreProvider) != null;
    final profileId = ref.watch(currentProfileIdProvider);
    final activeSessionId = ref.watch(currentRoutineSessionIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel semanal'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            Container(
              decoration: BoxDecoration(
                color: HabitarColors.sunlit,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acompanamiento de la semana',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: HabitarSpacing.sm),
                  const Text(
                    'Un resumen simple para decidir que rutina, habito o apoyo conviene atender hoy.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: HabitarSpacing.md),
            _LocalStorageCard(
              hasLocalStore: hasLocalStore,
              profileId: profileId,
              activeSessionId: activeSessionId,
            ),
            const _StatusCard(
              title: 'Habitos nuevos',
              body:
                  'Limite recomendado activo y conectado a la creacion de habitos.',
            ),
            FilledButton(
              onPressed: () => context.go('/habits'),
              child: const Text('Gestionar habitos'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            const _StatusCard(
              title: 'Rutinas',
              body:
                  'Crea una rutina breve y ejecutala paso a paso desde la vista infantil.',
            ),
            FilledButton(
              onPressed: () => context.go('/routine/create'),
              child: const Text('Crear rutina guiada'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            const _StatusCard(
              title: 'Modo baja estimulacion',
              body:
                  'Tema visual calmado preparado. Los controles finos llegan con preferencias persistentes.',
            ),
            const _StatusCard(
              title: 'Recordatorios',
              body:
                  'Configura consentimiento e intensidad. Las integraciones nativas quedan marcadas por plataforma.',
            ),
            FilledButton(
              onPressed: () => context.go('/notifications'),
              child: const Text('Configurar recordatorios'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            const _StatusCard(
              title: 'Emociones y apoyos',
              body:
                  'Check-in opcional con energia, sobrecarga y acciones breves.',
            ),
            FilledButton(
              onPressed: () => context.go('/wellbeing'),
              child: const Text('Registrar check-in'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            const _StatusCard(
              title: 'Cuentos',
              body:
                  'Biblioteca demo con preguntas, actividad y progreso simple.',
            ),
            FilledButton(
              onPressed: () => context.go('/stories'),
              child: const Text('Abrir cuentos'),
            ),
            const SizedBox(height: HabitarSpacing.md),
            const _StatusCard(
              title: 'Wearables',
              body:
                  'Preparacion separada para watchOS y Wear OS con acciones rapidas.',
            ),
            FilledButton(
              onPressed: () => context.go('/wearables'),
              child: const Text('Preparar wearables'),
            ),
          ],
        ),
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

class _LocalStorageCard extends StatelessWidget {
  const _LocalStorageCard({
    required this.hasLocalStore,
    required this.profileId,
    required this.activeSessionId,
  });

  final bool hasLocalStore;
  final String? profileId;
  final String? activeSessionId;

  @override
  Widget build(BuildContext context) {
    final title =
        hasLocalStore ? 'Guardado en este dispositivo' : 'Modo temporal';
    final body = hasLocalStore
        ? 'Perfil recuperado localmente${activeSessionId == null ? '.' : ' con una rutina activa.'}'
        : 'Este entorno usa datos en memoria para preview o pruebas.';

    return Card(
      margin: const EdgeInsets.only(bottom: HabitarSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.sm),
            Text(body),
            if (profileId != null) ...[
              const SizedBox(height: HabitarSpacing.sm),
              Text('Perfil activo: $profileId'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HabitarSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.sm),
            Text(body),
          ],
        ),
      ),
    );
  }
}
