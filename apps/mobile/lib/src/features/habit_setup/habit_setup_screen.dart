import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class HabitSetupScreen extends ConsumerStatefulWidget {
  const HabitSetupScreen({super.key});

  @override
  ConsumerState<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends ConsumerState<HabitSetupScreen> {
  final _titleController = TextEditingController(text: 'Higiene dental');
  final _minimumController =
      TextEditingController(text: 'Entrar al bano y preparar el cepillo');
  var _confirmOverride = false;
  String? _message;
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadHabits);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _minimumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            Text('Activacion gradual',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.md),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Habito nuevo')),
            const SizedBox(height: HabitarSpacing.md),
            TextField(
                controller: _minimumController,
                decoration: const InputDecoration(labelText: 'Version minima')),
            const SizedBox(height: HabitarSpacing.sm),
            CheckboxListTile(
              value: _confirmOverride,
              onChanged: (value) =>
                  setState(() => _confirmOverride = value ?? false),
              title: const Text(
                  'Confirmar excepcion si supera el limite recomendado'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton(
                onPressed: _createHabit, child: const Text('Agregar habito')),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
            const SizedBox(height: HabitarSpacing.lg),
            Text('Panel semanal',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.md),
            for (final habit in _habits)
              _HabitCard(habit: habit, onRecord: () => _recordProgress(habit)),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHabits() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      return;
    }
    final habits =
        await ref.read(habitServiceProvider).habitsForProfile(profileId);
    if (mounted) {
      setState(() => _habits = habits);
    }
  }

  Future<void> _createHabit() async {
    final profileId = ref.read(currentProfileIdProvider);
    final profileKind = ref.read(currentProfileKindProvider);
    if (profileId == null || profileKind == null) {
      setState(() => _message = 'Primero crea un perfil.');
      return;
    }

    final result = await ref.read(habitServiceProvider).createNewHabit(
          CreateHabitInput(
            profileId: profileId,
            profileKind: profileKind,
            title: _titleController.text.trim(),
            minimumVersion: _minimumController.text.trim(),
            confirmedOverride: _confirmOverride,
          ),
        );

    final warning = result.plan.decision.warning;
    setState(() {
      _message = result.wasActivated
          ? 'Habito activado con version minima. Hoy retomamos desde aqui.'
          : warning ?? 'El habito quedo propuesto para evitar sobrecarga.';
    });
    await _loadHabits();
  }

  Future<void> _recordProgress(Habit habit) async {
    await ref.read(habitServiceProvider).recordMinimumVersion(
          habitId: habit.metadata.id,
          completed: true,
          helpLevel: 2,
          ease: 3,
        );
    final summaries =
        await ref.read(habitServiceProvider).weeklySummaries(habit.profileId);
    final summary =
        summaries.where((item) => item.habitId == habit.metadata.id).first;
    if (mounted) {
      setState(() => _message = summary.supportiveInsight);
    }
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.onRecord});

  final Habit habit;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HabitarSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habit.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.sm),
            Text('Estado: ${habit.status.name}'),
            if (habit.minimumVersion != null)
              Text('Version minima: ${habit.minimumVersion}'),
            const SizedBox(height: HabitarSpacing.md),
            OutlinedButton(
                onPressed: onRecord,
                child: const Text('Registrar version minima')),
          ],
        ),
      ),
    );
  }
}
