import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  late Future<List<ProfileProgressSummary>> _summariesFuture;

  @override
  void initState() {
    super.initState();
    _summariesFuture = _loadSummaries();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileId = ref.watch(currentProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles'),
        actions: [
          IconButton(
            tooltip: 'Crear perfil',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<ProfileProgressSummary>>(
          future: _summariesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                title: 'No pudimos cargar los perfiles',
                body: 'Puedes volver al panel e intentar de nuevo.',
                actionLabel: 'Volver al panel',
                onAction: () => context.go('/dashboard'),
              );
            }
            final summaries = snapshot.data ?? const [];
            if (summaries.isEmpty) {
              return _MessageState(
                title: 'Todavia no hay perfiles',
                body:
                    'Crea un perfil infantil o adolescente para ver progreso, metas y tareas.',
                actionLabel: 'Crear perfil',
                onAction: () => context.go('/profile'),
              );
            }
            return ListView(
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
                      Text('Progreso familiar',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: HabitarSpacing.sm),
                      const Text(
                        'Cada perfil puede ver que avanzo, que falta y cual es el proximo paso.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HabitarSpacing.lg),
                for (final summary in summaries)
                  _ProfileProgressCard(
                    summary: summary,
                    isActive: summary.profileId == activeProfileId,
                    onSelect: () => _selectProfile(summary),
                    onRoutine: () {
                      _selectProfile(summary);
                      context.go('/routine/player');
                    },
                    onHabits: () {
                      _selectProfile(summary);
                      context.go('/habits');
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<ProfileProgressSummary>> _loadSummaries() async {
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) {
      return const [];
    }
    return ref.read(profileServiceProvider).summariesForFamily(familyId);
  }

  void _selectProfile(ProfileProgressSummary summary) {
    ref.read(currentProfileIdProvider.notifier).state = summary.profileId;
    ref.read(currentProfileKindProvider.notifier).state = summary.kind;
  }
}

class _ProfileProgressCard extends StatelessWidget {
  const _ProfileProgressCard({
    required this.summary,
    required this.isActive,
    required this.onSelect,
    required this.onRoutine,
    required this.onHabits,
  });

  final ProfileProgressSummary summary;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onRoutine;
  final VoidCallback onHabits;

  @override
  Widget build(BuildContext context) {
    final kindLabel =
        summary.kind == ProfileKind.child ? 'Infantil' : 'Adolescente';
    final percent = (summary.progressFraction * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: HabitarSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.displayName,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: HabitarSpacing.xs),
                      Text('$kindLabel, ${summary.age} anos'),
                    ],
                  ),
                ),
                if (isActive)
                  const Chip(label: Text('Activo'))
                else
                  TextButton(
                    onPressed: onSelect,
                    child: const Text('Usar'),
                  ),
              ],
            ),
            const SizedBox(height: HabitarSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.progressFraction,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: HabitarSpacing.sm),
            Text('$percent% de lo visible completado'),
            const SizedBox(height: HabitarSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Metas cumplidas',
                    value: summary.completedGoals.toString(),
                    color: HabitarColors.calmGreen,
                  ),
                ),
                const SizedBox(width: HabitarSpacing.sm),
                Expanded(
                  child: _MetricTile(
                    label: 'Pendientes',
                    value: summary.pendingTasks.toString(),
                    color: HabitarColors.warmGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HabitarSpacing.md),
            if (summary.activeRoutineTitle != null)
              Text('Rutina activa: ${summary.activeRoutineTitle}')
            else
              const Text(
                  'No hay rutina activa ahora. Un adulto puede preparar una.'),
            if (summary.nextTaskTitle != null) ...[
              const SizedBox(height: HabitarSpacing.xs),
              Text('Proximo paso: ${summary.nextTaskTitle}'),
            ],
            const SizedBox(height: HabitarSpacing.sm),
            Text(summary.message),
            const SizedBox(height: HabitarSpacing.md),
            Wrap(
              spacing: HabitarSpacing.sm,
              runSpacing: HabitarSpacing.sm,
              children: [
                if (summary.activeRoutineTitle != null)
                  FilledButton(
                    onPressed: onRoutine,
                    child: const Text('Ver tarea'),
                  ),
                if (summary.habitsCount > 0)
                  OutlinedButton(
                    onPressed: onHabits,
                    child: const Text('Ver habitos'),
                  )
                else
                  const _AdultManagedNote(
                    text:
                        'Los habitos los prepara un adulto, tutor, profesional o docente.',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HabitarSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: HabitarSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _AdultManagedNote extends StatelessWidget {
  const _AdultManagedNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: HabitarSpacing.md,
        vertical: HabitarSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: HabitarColors.softBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.sm),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: HabitarSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
