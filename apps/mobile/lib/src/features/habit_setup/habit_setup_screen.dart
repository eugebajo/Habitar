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
      TextEditingController(text: 'Entrar al baño y preparar el cepillo');
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
      appBar: AppBar(title: const Text('Hábitos cuidados')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            const HabitarMoment(
              title: 'Elijamos algo pequeño.',
              body:
                  'Un hábito nuevo debe sentirse posible. Si pesa demasiado, lo hacemos más pequeño.',
              color: HabitarColors.surfaceWarm,
            ),
            const SizedBox(height: HabitarSpacing.md),
            TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: '¿Qué queremos cuidar?')),
            const SizedBox(height: HabitarSpacing.md),
            TextField(
                controller: _minimumController,
                decoration:
                    const InputDecoration(labelText: 'Paso mínimo posible')),
            const SizedBox(height: HabitarSpacing.sm),
            CheckboxListTile(
              value: _confirmOverride,
              onChanged: (value) =>
                  setState(() => _confirmOverride = value ?? false),
              title: const Text(
                  'Hoy podemos sostener un poco más si un adulto lo decide'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton(
                onPressed: _createHabit, child: const Text('Preparar hábito')),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
            const SizedBox(height: HabitarSpacing.lg),
            Text('Lo que estamos cuidando',
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
      setState(() => _message = 'Primero creá un perfil.');
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
          ? 'Listo. Lo vamos a acompañar desde el paso más pequeño.'
          : warning ?? 'Lo dejamos preparado sin sumar carga hoy.';
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
            Text(_statusText(habit.status)),
            if (habit.minimumVersion != null)
              Text('Paso mínimo: ${habit.minimumVersion}'),
            const SizedBox(height: HabitarSpacing.md),
            OutlinedButton(
                onPressed: onRecord, child: const Text('Hoy lo logramos')),
          ],
        ),
      ),
    );
  }

  String _statusText(HabitStatus status) {
    return switch (status) {
      HabitStatus.proposed => 'Preparado para más adelante',
      HabitStatus.newHabit => 'Nuevo y acompañado',
      HabitStatus.practicing => 'En práctica',
      HabitStatus.stable => 'Ya se siente más estable',
      HabitStatus.paused => 'Pausado con cuidado',
      HabitStatus.archived => 'Guardado en historial',
    };
  }
}
