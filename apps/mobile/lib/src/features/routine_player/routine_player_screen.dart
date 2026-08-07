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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : session == null
                ? const _EmptyRoutine()
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
    if (mounted) setState(() => _session = updated);
  }
}

class _RoutineBody extends StatelessWidget {
  const _RoutineBody(
      {required this.session,
      required this.onDone,
      required this.onMoreTime,
      required this.onPause,
      required this.onResume,
      required this.onHelp,
      required this.onPostpone,
      required this.onSkip});

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
    final totalSteps = session.orderedSteps.length;
    final stepNumber = (session.activeStepIndex + 1)
        .clamp(1, totalSteps == 0 ? 1 : totalSteps);
    final progress = session.progressFraction.clamp(0, 1).toDouble();
    final estimatedStepMinutes = activeStep?.estimatedMinutes;

    return HabitarPage(
      maxWidth: 620,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      children: [
        Row(children: [
          IconButton(
              onPressed: () => context.go('/child'),
              icon: const Icon(Icons.arrow_back_rounded)),
          const Spacer(),
          const HabitarWordmark(compact: true),
          const Spacer(),
          const SizedBox(width: 48),
        ]),
        const SizedBox(height: 12),
        Text(
            isComplete ? 'Camino terminado' : 'Paso $stepNumber de $totalSteps',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: HabitarColors.surfaceWarm,
                color: HabitarColors.primaryGreen)),
        const SizedBox(height: 28),
        HabitarCard(
          borderColor: HabitarColors.primaryGreen.withValues(alpha: .35),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HabitarPill(
              icon: Icons.wb_sunny_outlined,
              label: isPaused
                  ? 'Pausa'
                  : estimatedStepMinutes == null
                      ? 'Ahora'
                      : 'Ahora · $estimatedStepMinutes min aprox.',
              color: HabitarColors.surfaceWarm,
            ),
            const SizedBox(height: 16),
            Text(
                isComplete
                    ? 'Terminamos por ahora.'
                    : activeStep?.title ?? 'Sin paso activo',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 10),
            SizedBox(height: 270, child: HabitarSoftIllustration(label: 'bag')),
          ]),
        ),
        const SizedBox(height: 14),
        if (!isComplete && nextStep != null)
          HabitarCard(
            color: HabitarColors.card,
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const HabitarPill(
                        label: 'Después', color: HabitarColors.surfaceWarm),
                    const SizedBox(height: 8),
                    Text(nextStep.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ])),
              const SizedBox(
                  width: 110,
                  height: 90,
                  child: HabitarSoftIllustration(label: 'shoes')),
            ]),
          ),
        const SizedBox(height: 18),
        if (!isComplete) ...[
          FilledButton(
              onPressed: isPaused ? onResume : onDone,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(isPaused ? 'Volver cuando quieras' : 'Listo'),
                const SizedBox(width: 14),
                const Icon(Icons.check_rounded)
              ])),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: onMoreTime,
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Necesito más tiempo')),
          const SizedBox(height: 10),
          if (session.routine.canRequestHelp) ...[
            OutlinedButton.icon(
                onPressed: onHelp,
                icon: const Icon(Icons.pan_tool_alt_rounded),
                label: Text(session.helpRequested
                    ? 'Ayuda solicitada'
                    : 'Necesito ayuda')),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
              onPressed: isPaused ? onResume : onPause,
              icon: const Icon(Icons.cloud_outlined),
              label: Text(isPaused ? 'Estoy listo' : 'Necesito una pausa')),
          const SizedBox(height: 8),
          if (session.routine.canPostpone)
            TextButton(
                onPressed: onPostpone, child: const Text('5 minutos después')),
          TextButton(onPressed: onSkip, child: const Text('Omitir este paso')),
        ],
      ],
    );
  }
}

class _EmptyRoutine extends StatelessWidget {
  const _EmptyRoutine();

  @override
  Widget build(BuildContext context) {
    return HabitarPage(children: [
      const SizedBox(height: 80),
      const EmptyState(
        icon: Icons.self_improvement_rounded,
        title: 'Hoy no hay una tarea preparada.',
        message:
            'Un adulto puede preparar el próximo paso. Por ahora podés respirar.',
      ),
      const SizedBox(height: 18),
      FilledButton(
          onPressed: () => context.go('/child'), child: const Text('Volver')),
    ]);
  }
}
