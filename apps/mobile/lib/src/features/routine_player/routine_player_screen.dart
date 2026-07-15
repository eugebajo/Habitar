import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

import '../../dependencies.dart';

class RoutinePlayerScreen extends ConsumerStatefulWidget {
  const RoutinePlayerScreen({super.key});

  @override
  ConsumerState<RoutinePlayerScreen> createState() =>
      _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends ConsumerState<RoutinePlayerScreen> {
  RoutineSession? _session;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSession);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('Rutina guiada')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : session == null
                ? _EmptyRoutine(onCreate: () => context.go('/routine/create'))
                : _RoutineBody(
                    session: session,
                    onDone: () =>
                        _update((service) => service.completeStep(session)),
                    onMoreTime: () =>
                        _update((service) => service.requestMoreTime(session)),
                    onPause: () => _update((service) =>
                        service.pause(session, RoutinePauseReason.sensory)),
                    onResume: () =>
                        _update((service) => service.resume(session)),
                    onHelp: () =>
                        _update((service) => service.requestHelp(session)),
                    onPostpone: () => _update((service) =>
                        service.postpone(session, const Duration(minutes: 5))),
                    onSkip: () =>
                        _update((service) => service.skipStep(session)),
                  ),
      ),
    );
  }

  Future<void> _loadSession() async {
    final sessionId = ref.read(currentRoutineSessionIdProvider);
    final profileId = ref.read(currentProfileIdProvider);
    final repository = ref.read(routineSessionRepositoryProvider);
    final session = sessionId != null ? await repository.byId(sessionId) : null;
    final fallback = profileId != null
        ? await repository.activeSessionForProfile(profileId)
        : null;
    if (mounted) {
      setState(() {
        _session = session ?? fallback;
        _isLoading = false;
      });
    }
  }

  Future<void> _update(
      Future<RoutineSession> Function(RoutineService service) action) async {
    final service = ref.read(routineServiceProvider);
    final updated = await action(service);
    ref.read(currentRoutineSessionIdProvider.notifier).state = updated.id;
    if (mounted) {
      setState(() => _session = updated);
    }
  }
}

class _RoutineBody extends StatelessWidget {
  const _RoutineBody({
    required this.session,
    required this.onDone,
    required this.onMoreTime,
    required this.onPause,
    required this.onResume,
    required this.onHelp,
    required this.onPostpone,
    required this.onSkip,
  });

  final RoutineSession session;
  final VoidCallback onDone;
  final VoidCallback onMoreTime;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onHelp;
  final VoidCallback onPostpone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final activeStep = session.activeStep;
    final nextStep = session.nextStep;
    final isPaused = session.status == RoutineSessionStatus.paused ||
        session.status == RoutineSessionStatus.postponed;
    final isComplete = session.status == RoutineSessionStatus.completed;

    return ListView(
      padding: const EdgeInsets.all(HabitarSpacing.lg),
      children: [
        Text(session.routine.title,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: HabitarSpacing.lg),
        LinearProgressIndicator(
            value: session.progressFraction.clamp(0, 1).toDouble()),
        const SizedBox(height: HabitarSpacing.lg),
        if (isComplete)
          const _MainStepCard(
              title: 'Rutina completa',
              subtitle: 'Hoy retomamos desde aqui cuando lo necesites.')
        else
          _MainStepCard(
            title: activeStep?.title ?? 'Sin paso activo',
            subtitle:
                isPaused ? 'Pausa activa. El progreso esta guardado.' : 'Ahora',
          ),
        const SizedBox(height: HabitarSpacing.md),
        _TimerPanel(
            minutes: session.estimatedRemainingMinutes, isPaused: isPaused),
        const SizedBox(height: HabitarSpacing.md),
        _NowNextPanel(
            nowTitle: activeStep?.title ?? 'Listo',
            nextTitle: nextStep?.title ?? 'Despues terminamos'),
        const SizedBox(height: HabitarSpacing.lg),
        if (!isComplete) ...[
          FilledButton(
              onPressed: isPaused ? onResume : onDone,
              child: Text(isPaused ? 'Reanudar' : 'Hecho')),
          const SizedBox(height: HabitarSpacing.sm),
          OutlinedButton(
              onPressed: onMoreTime, child: const Text('Necesito mas tiempo')),
          const SizedBox(height: HabitarSpacing.sm),
          OutlinedButton(
              onPressed: onHelp,
              child: Text(session.helpRequested
                  ? 'Ayuda solicitada'
                  : 'Necesito ayuda')),
          const SizedBox(height: HabitarSpacing.sm),
          OutlinedButton(
              onPressed: isPaused ? onResume : onPause,
              child: Text(isPaused ? 'Volver a la rutina' : 'Pausa sensorial')),
          const SizedBox(height: HabitarSpacing.sm),
          OutlinedButton(
              onPressed: onPostpone, child: const Text('5 minutos despues')),
          const SizedBox(height: HabitarSpacing.sm),
          TextButton(onPressed: onSkip, child: const Text('Omitir este paso')),
        ],
      ],
    );
  }
}

class _MainStepCard extends StatelessWidget {
  const _MainStepCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.md),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({required this.minutes, required this.isPaused});

  final int minutes;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                  value: isPaused ? 0 : 0.65, strokeWidth: 8),
            ),
            const SizedBox(width: HabitarSpacing.md),
            Expanded(
              child: Text(isPaused
                  ? 'Temporizador pausado'
                  : 'Tiempo aproximado restante: $minutes min'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowNextPanel extends StatelessWidget {
  const _NowNextPanel({required this.nowTitle, required this.nextTitle});

  final String nowTitle;
  final String nextTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SmallPanel(label: 'Ahora', title: nowTitle)),
        const SizedBox(width: HabitarSpacing.sm),
        Expanded(child: _SmallPanel(label: 'Despues', title: nextTitle)),
      ],
    );
  }
}

class _SmallPanel extends StatelessWidget {
  const _SmallPanel({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.sm),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoutine extends StatelessWidget {
  const _EmptyRoutine({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Todavia no hay una rutina activa.'),
            const SizedBox(height: HabitarSpacing.md),
            FilledButton(
                onPressed: onCreate, child: const Text('Crear rutina')),
          ],
        ),
      ),
    );
  }
}
