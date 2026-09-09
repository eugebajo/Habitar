import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../components/adult_shell.dart';
import '../../dependencies.dart';
import '../../routine_reminders.dart';
import '../../routine_today.dart';
import '../../selected_profile.dart';

class AdultSectionScreen extends StatelessWidget {
  const AdultSectionScreen({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      'routines' => const _RoutinesSection(),
      'progress' => const _ProgressSection(),
      'habits' => _GenericAdultSection(
          title: 'Hábitos',
          subtitle: 'Activá como máximo tres cambios pequeños a la vez.',
          icon: Icons.eco_rounded,
          actionPath: '/habits',
          actionLabel: 'Crear hábito',
        ),
      'settings' => const _SettingsSection(),
      _ => _GenericAdultSection(
          title: 'Habitar',
          subtitle: 'Un espacio familiar para avanzar paso a paso.',
          icon: Icons.favorite_rounded,
          actionPath: '/dashboard',
          actionLabel: 'Ir al inicio',
        ),
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return AdultPage(
      title: 'Configuración',
      subtitle: 'Ajustá accesibilidad, privacidad y experiencia sensorial.',
      action: FilledButton.icon(
        onPressed: () => context.go('/privacy'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Privacidad'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => context.go('/account'),
            child: const Text('Cuenta'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/notifications'),
            child: const Text('Notificaciones'),
          ),
        ],
      ),
    );
  }
}

class _RoutinesSection extends ConsumerStatefulWidget {
  const _RoutinesSection();

  @override
  ConsumerState<_RoutinesSection> createState() => _RoutinesSectionState();
}

class _RoutinesSectionState extends ConsumerState<_RoutinesSection> {
  late Future<List<_RoutineView>> _future;
  final Set<String> _deletingRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_RoutineView>> _load() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      return const [];
    }
    final repository = ref.read(routineRepositoryProvider);
    final routines = await repository.routinesForProfile(profileId);
    final views = <_RoutineView>[];
    for (final routine in routines) {
      final steps = await repository.stepsForRoutine(routine.metadata.id);
      views.add(_RoutineView(routine: routine, steps: steps));
    }
    return views;
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _setStatus(Routine routine, EntityStatus status) async {
    final updated = await ref
        .read(routineRepositoryProvider)
        .updateRoutineStatus(routine.metadata.id, status);
    if (status == EntityStatus.active) {
      final steps = await ref
          .read(routineRepositoryProvider)
          .stepsForRoutine(updated.metadata.id);
      final profile = await loadSelectedProfile(ref);
      await scheduleRoutineReminders(
        ref,
        routine: updated,
        steps: steps,
        profileName: profile?.displayName ?? 'este perfil',
      );
    } else {
      await cancelRoutineReminders(ref, routine.metadata.id);
    }
    _refresh();
  }

  Future<void> _duplicate(Routine routine) async {
    final copy = await ref
        .read(routineRepositoryProvider)
        .duplicateRoutine(routine.metadata.id);
    if (!mounted) {
      return;
    }
    context.go('/routine/create?edit=${copy.metadata.id}');
  }

  Future<void> _adjustToday(Routine routine) async {
    final selected = await showModalBottomSheet<_TodayAdjustment>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AdjustTodaySheet(),
    );
    if (selected == null) {
      return;
    }
    TimeOfDay? newTime;
    if (selected.type == RoutineOverrideType.changeTime && mounted) {
      newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: routine.scheduledHour ?? TimeOfDay.now().hour,
          minute: routine.scheduledMinute ?? 0,
        ),
      );
      if (newTime == null) {
        return;
      }
    }
    final now = DateTime.now();
    final overrideId =
        '${routine.metadata.id}-${now.year}-${now.month}-${now.day}';
    await ref.read(routineOverrideRepositoryProvider).saveOverride(
          RoutineOverride(
            metadata: EntityMetadata(
              id: overrideId,
              createdAt: now,
              updatedAt: now,
              ownerId: routine.metadata.ownerId,
            ),
            routineId: routine.metadata.id,
            profileId: routine.profileId,
            date: now,
            type: selected.type,
            startHour: newTime?.hour,
            startMinute: newTime?.minute,
            isPaused: selected.isPaused,
            note: selected.note,
          ),
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ajuste guardado para hoy: ${selected.note}.')),
    );
    _refresh();
  }

  Future<void> _confirmDelete(Routine routine) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar esta rutina?'),
            content: const Text(
              'Se eliminará de las rutinas activas y dejarán de programarse '
              'sus recordatorios. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar rutina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    setState(() => _deletingRoutineIds.add(routine.metadata.id));
    try {
      await _setStatus(routine, EntityStatus.deleted);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rutina eliminada de las activas.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos eliminar la rutina. Revisá tus permisos e intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingRoutineIds.remove(routine.metadata.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(currentProfileIdProvider);
    return AdultPage(
      title: 'Rutinas',
      subtitle: 'Organizá el día familiar con rutinas claras y previsibles.',
      action: FilledButton.icon(
        onPressed: () => context.go('/routine/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva rutina'),
      ),
      child: Column(
        children: [
          _ProfileSelector(onTap: () => context.go('/profiles')),
          const SizedBox(height: 16),
          if (profileId == null)
            HabitarConversationCard(
              title: 'Elegí un perfil',
              body:
                  'Primero seleccioná a qué niño o adolescente querés acompañar.',
              color: HabitarColors.surfaceMist,
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person_search_rounded,
                    color: HabitarColors.deepGreen),
              ),
              child: FilledButton(
                onPressed: () => context.go('/profiles'),
                child: const Text('Elegir perfil'),
              ),
            )
          else
            FutureBuilder<List<_RoutineView>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return HabitarConversationCard(
                    title: 'No pudimos cargar las rutinas',
                    body:
                        'Revisá la conexión e intentá nuevamente en un momento.',
                    color: HabitarColors.surfaceWarm,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.error_outline_rounded,
                          color: HabitarColors.deepGreen),
                    ),
                    child: OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  );
                }
                final routines = snapshot.data ?? const [];
                if (routines.isEmpty) {
                  return HabitarConversationCard(
                    title: 'Todavía no hay rutinas',
                    body:
                        'Creá una rutina con horario y pasos claros para que aparezca acá.',
                    color: HabitarColors.surfaceMist,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.add_task_rounded,
                          color: HabitarColors.deepGreen),
                    ),
                    child: FilledButton.icon(
                      onPressed: () => context.go('/routine/create'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nueva rutina'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final view in routines) ...[
                      _RoutineTile(
                        view: view,
                        onEdit: () => context.go(
                            '/routine/create?edit=${view.routine.metadata.id}'),
                        onDuplicate: () => _duplicate(view.routine),
                        onAdjustToday: () => _adjustToday(view.routine),
                        onPause: () => _setStatus(
                          view.routine,
                          view.routine.metadata.status == EntityStatus.paused
                              ? EntityStatus.active
                              : EntityStatus.paused,
                        ),
                        onDelete: () => _confirmDelete(view.routine),
                        isDeleting: _deletingRoutineIds.contains(
                          view.routine.metadata.id,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 18),
          const HabitarConversationCard(
            title: 'Consejo de Habitar',
            body:
                'La constancia crea seguridad. Repetir las rutinas todos los días ayuda a sentir más calma.',
            color: HabitarColors.surfaceMist,
            leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.favorite_border_rounded,
                    color: HabitarColors.deepGreen)),
          ),
        ],
      ),
    );
  }
}

class _ProfileSelector extends ConsumerWidget {
  const _ProfileSelector({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
        future: loadSelectedProfile(ref),
        builder: (context, snapshot) {
          final name = snapshot.data?.displayName ?? 'Elegir perfil';
          return HabitarCard(
            padding: const EdgeInsets.all(12),
            onTap: onTap,
            child: Row(children: [
              HabitarAvatar(label: name, size: 50),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: HabitarColors.deepGreen,
                          fontSize: 18))),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ]),
          );
        },
      );
}

class _RoutineView {
  const _RoutineView({required this.routine, required this.steps});
  final Routine routine;
  final List<RoutineStep> steps;
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({
    required this.view,
    required this.onEdit,
    required this.onDuplicate,
    required this.onAdjustToday,
    required this.onPause,
    required this.onDelete,
    this.isDeleting = false,
  });

  final _RoutineView view;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onAdjustToday;
  final VoidCallback onPause;
  final VoidCallback onDelete;
  final bool isDeleting;

  IconData get _icon {
    final title = view.routine.title.toLowerCase();
    if (title.contains('noche') || title.contains('dorm')) {
      return Icons.nightlight_round;
    }
    if (title.contains('escuela') || title.contains('mochila')) {
      return Icons.backpack_outlined;
    }
    if (title.contains('mañana') || title.contains('despert')) {
      return Icons.wb_sunny_outlined;
    }
    return Icons.route_rounded;
  }

  String get _time => view.routine.scheduledTimeLabel ?? 'Sin horario';

  String get _status {
    return switch (view.routine.metadata.status) {
      EntityStatus.paused => 'Pausada',
      EntityStatus.archived => 'Archivada',
      _ => view.routine.hasSchedule ? 'Programada' : 'Activa',
    };
  }

  Color get _statusColor {
    return switch (view.routine.metadata.status) {
      EntityStatus.paused => HabitarColors.surfaceWarm,
      EntityStatus.archived => const Color(0xFFEAF0F8),
      _ => HabitarColors.surfaceMist,
    };
  }

  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Column(children: [
          Row(children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: HabitarColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(18)),
              child: Icon(_icon, color: HabitarColors.deepGreen, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(view.routine.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Wrap(spacing: 12, children: [
                    _MiniMeta(icon: Icons.schedule_rounded, label: _time),
                    _MiniMeta(
                      icon: Icons.format_list_bulleted_rounded,
                      label: '${view.steps.length} pasos',
                    ),
                  ]),
                ])),
            Flexible(
              child: HabitarPill(
                  label: _status,
                  icon: Icons.check_circle_rounded,
                  color: _statusColor),
            ),
          ]),
          const Divider(height: 28, color: HabitarColors.line),
          Wrap(alignment: WrapAlignment.spaceAround, spacing: 8, children: [
            _TileAction(
                icon: Icons.edit_outlined, label: 'Editar', onTap: onEdit),
            _TileAction(
                icon: Icons.content_copy_rounded,
                label: 'Duplicar',
                onTap: onDuplicate),
            _TileAction(
                icon: Icons.today_rounded, label: 'Hoy', onTap: onAdjustToday),
            _TileAction(
              icon: view.routine.metadata.status == EntityStatus.paused
                  ? Icons.play_circle_outline_rounded
                  : Icons.pause_circle_outline_rounded,
              label: view.routine.metadata.status == EntityStatus.paused
                  ? 'Activar'
                  : 'Pausar',
              onTap: onPause,
            ),
            _TileAction(
              icon: Icons.delete_outline_rounded,
              label: isDeleting ? 'Eliminando' : 'Eliminar',
              onTap: isDeleting ? null : onDelete,
            ),
          ]),
        ]),
      );
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: HabitarColors.mutedInk),
        const SizedBox(width: 5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis))
      ]);
}

class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Text(label),
          ]),
        ),
      );
}

class _TodayAdjustment {
  const _TodayAdjustment({
    required this.type,
    required this.note,
    this.isPaused = false,
  });

  final RoutineOverrideType type;
  final String note;
  final bool isPaused;
}

class _AdjustTodaySheet extends StatelessWidget {
  const _AdjustTodaySheet();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ajustar solo hoy',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                  'Cambiá esta rutina sin modificar la programación habitual.'),
              const SizedBox(height: 12),
              _AdjustTodayAction(
                icon: Icons.schedule_rounded,
                label: 'Cambiar horario de hoy',
                adjustment: const _TodayAdjustment(
                  type: RoutineOverrideType.changeTime,
                  note: 'horario cambiado',
                ),
              ),
              _AdjustTodayAction(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Pausar por hoy',
                adjustment: const _TodayAdjustment(
                  type: RoutineOverrideType.pauseToday,
                  note: 'pausada por hoy',
                  isPaused: true,
                ),
              ),
              _AdjustTodayAction(
                icon: Icons.directions_run_rounded,
                label: 'Vamos tarde',
                adjustment: const _TodayAdjustment(
                  type: RoutineOverrideType.runningLate,
                  note: 'familia con retraso',
                ),
              ),
              _AdjustTodayAction(
                icon: Icons.healing_rounded,
                label: 'Día de descanso',
                adjustment: const _TodayAdjustment(
                  type: RoutineOverrideType.sick,
                  note: 'día de descanso',
                  isPaused: true,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AdjustTodayAction extends StatelessWidget {
  const _AdjustTodayAction({
    required this.icon,
    required this.label,
    required this.adjustment,
  });

  final IconData icon;
  final String label;
  final _TodayAdjustment adjustment;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: HabitarColors.deepGreen),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pop(adjustment),
      );
}

class _ProgressSection extends ConsumerWidget {
  const _ProgressSection();

  Future<_ProgressReportData> _loadReport(WidgetRef ref) async {
    final profile = await loadSelectedProfile(ref);
    if (profile == null) {
      return const _ProgressReportData.empty();
    }
    final routineRepository = ref.read(routineRepositoryProvider);
    final routines = await routineRepository.routinesForProfile(profile.id);
    final today = habitarFunctionalDate();
    final overrides = await ref
        .read(routineOverrideRepositoryProvider)
        .overridesForProfileDate(profileId: profile.id, date: today);
    final scheduledRoutines = routines
        .where(
          (routine) =>
              routine.metadata.status == EntityStatus.active &&
              routineAppliesOnDate(routine, today),
        )
        .toList(growable: false);
    var steps = 0;
    for (final routine in scheduledRoutines) {
      steps +=
          (await routineRepository.stepsForRoutine(routine.metadata.id)).length;
    }
    final sessionsToday = await ref
        .read(routineSessionRepositoryProvider)
        .sessionsForProfileDate(profileId: profile.id, localDate: today);
    final completedSteps = sessionsToday
        .expand((session) => session.completedStepIds)
        .toSet()
        .length
        .clamp(0, steps);
    return _ProgressReportData(
      profileName: profile.displayName,
      routines: scheduledRoutines.length,
      steps: steps,
      completedSteps: completedSteps,
      activeRoutines: scheduledRoutines.length,
      pausedToday: overrides.where((override) => override.isPaused).length,
      adjustedToday: overrides.length,
    );
  }

  Future<void> _shareReport(BuildContext context, WidgetRef ref) async {
    final data = await _loadReport(ref);
    final bytes = await _buildWeeklyReportPdf(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte-habitar-semanal.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdultPage(
        title: 'Progreso semanal',
        subtitle: 'Una mirada simple, sin comparaciones ni castigos.',
        child: FutureBuilder<_ProgressReportData>(
          future: _loadReport(ref),
          key: ValueKey(ref.watch(currentProfileIdProvider)),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? const _ProgressReportData.empty();
            final completed = data.completedSteps;
            final pending = (data.steps - completed).clamp(0, data.steps);
            final progress = data.progressFraction;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HabitarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: HabitarColors.primaryGreen),
                          Text(
                            'Resumen semanal',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 520;
                          final ring = ProgressRing(
                            value: progress,
                            size: compact ? 112 : 142,
                          );
                          final summary = Column(
                            crossAxisAlignment: compact
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.steps == 0
                                    ? 'Sin progreso registrado'
                                    : '${(progress * 100).round()}% completado esta semana',
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$completed de ${data.steps} pasos completados',
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                alignment: compact
                                    ? WrapAlignment.center
                                    : WrapAlignment.start,
                                children: [
                                  _LegendDot(
                                    color: HabitarColors.primaryGreen,
                                    label: 'Completado ($completed)',
                                  ),
                                  _LegendDot(
                                    color: const Color(0xFFEADDC8),
                                    label: 'Pendiente ($pending)',
                                  ),
                                ],
                              ),
                            ],
                          );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ring,
                                const SizedBox(height: 14),
                                summary,
                              ],
                            );
                          }
                          return Row(children: [
                            ring,
                            const SizedBox(width: 22),
                            Expanded(child: summary),
                          ]);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProgressStatGrid(
                  stats: [
                    _ProgressStatData(
                      icon: Icons.check_circle_outline,
                      value: completed.toString(),
                      label: 'Pasos completados',
                      note: 'datos reales',
                    ),
                    _ProgressStatData(
                      icon: Icons.eco_rounded,
                      value: data.activeRoutines.toString(),
                      label: 'Rutinas en marcha',
                      note: '${data.routines} creadas',
                    ),
                    _ProgressStatData(
                      icon: Icons.today_rounded,
                      value: data.adjustedToday.toString(),
                      label: 'Ajustes de hoy',
                      note: '${data.pausedToday} pausas',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Reporte y logros',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _shareReport(context, ref),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Descargar reporte PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _shareReport(context, ref),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Compartir'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HabitarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Reporte semanal de ${data.profileName}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'Generado hoy',
                            style: TextStyle(color: HabitarColors.mutedInk),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CategoryBar(label: 'Rutinas', value: progress),
                      _CategoryBar(
                          label: 'Ajustes hoy', value: data.adjustmentFraction),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 7, backgroundColor: color),
          const SizedBox(width: 8),
          Flexible(child: Text(label, softWrap: true)),
        ],
      );
}

class _ProgressStatData {
  const _ProgressStatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final String value;
  final String label;
  final String note;
}

class _ProgressStatGrid extends StatelessWidget {
  const _ProgressStatGrid({required this.stats});

  final List<_ProgressStatData> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 430;
        final spacing = useTwoColumns ? 12.0 : 10.0;
        final width = useTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _ProgressStat(
                  icon: stat.icon,
                  value: stat.value,
                  label: stat.label,
                  note: stat.note,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.note});
  final IconData icon;
  final String value;
  final String label;
  final String note;
  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: HabitarColors.surfaceMist,
              child: Icon(icon, color: HabitarColors.deepGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    label,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    note,
                    softWrap: true,
                    style: const TextStyle(color: HabitarColors.mutedInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: HabitarColors.surfaceMist,
                      color: HabitarColors.primaryGreen))),
          const SizedBox(width: 10),
          Text('${(value * 100).round()}%'),
        ]),
      );
}

class _ProgressReportData {
  const _ProgressReportData({
    required this.profileName,
    required this.routines,
    required this.steps,
    required this.completedSteps,
    required this.activeRoutines,
    required this.pausedToday,
    required this.adjustedToday,
  });

  const _ProgressReportData.empty()
      : profileName = 'Sin perfil',
        routines = 0,
        steps = 0,
        completedSteps = 0,
        activeRoutines = 0,
        pausedToday = 0,
        adjustedToday = 0;

  final String profileName;
  final int routines;
  final int steps;
  final int completedSteps;
  final int activeRoutines;
  final int pausedToday;
  final int adjustedToday;

  double get progressFraction => steps == 0 ? 0 : completedSteps / steps;
  double get adjustmentFraction =>
      routines == 0 ? 0 : (adjustedToday / routines).clamp(0, 1).toDouble();
}

Future<Uint8List> _buildWeeklyReportPdf(_ProgressReportData data) async {
  final document = pw.Document();
  final regularFont = await PdfGoogleFonts.robotoRegular();
  final boldFont = await PdfGoogleFonts.robotoBold();
  final now = DateTime.now();
  document.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Habitar',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Reporte semanal de ${data.profileName}'),
            pw.Text('Generado el ${now.day}/${now.month}/${now.year}'),
            pw.SizedBox(height: 24),
            pw.Text(
              'Resumen',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _pdfMetric('Rutinas creadas', data.routines.toString()),
            _pdfMetric('Rutinas activas', data.activeRoutines.toString()),
            _pdfMetric('Pasos configurados', data.steps.toString()),
            _pdfMetric(
              'Pasos completados',
              '${data.completedSteps} de ${data.steps}',
            ),
            _pdfMetric('Ajustes aplicados hoy', data.adjustedToday.toString()),
            _pdfMetric('Pausas de hoy', data.pausedToday.toString()),
            pw.SizedBox(height: 24),
            pw.Text(
              'Este reporte usa datos registrados en Habitar y evita comparaciones o castigos. La lectura recomendada es observar que ayudo y que necesita menos friccion.',
            ),
          ],
        ),
      ),
    ),
  );
  return document.save();
}

pw.Widget _pdfMetric(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

class _GenericAdultSection extends StatelessWidget {
  const _GenericAdultSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.actionPath,
      required this.actionLabel});
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionPath;
  final String actionLabel;
  @override
  Widget build(BuildContext context) => AdultPage(
        title: title,
        subtitle: subtitle,
        action: FilledButton.icon(
            onPressed: () => context.go(actionPath),
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel)),
        child: GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            _Stat(icon: icon, label: subtitle, value: 'Todo listo'),
            const _Stat(
                icon: Icons.check_circle_outline,
                label: 'Completados esta semana',
                value: 'Sin registros'),
            const _Stat(
                icon: Icons.favorite_outline,
                label: 'Logro reciente',
                value: 'Sin eventos'),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Row(children: [
          CircleAvatar(
              backgroundColor: HabitarColors.surfaceMist,
              child: Icon(icon, color: HabitarColors.deepGreen)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label,
                    maxLines: 2,
                    style: const TextStyle(color: HabitarColors.mutedInk)),
              ])),
        ]),
      );
}

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  Future<_ChildHomeData> _load(WidgetRef ref) async {
    final profile = await loadSelectedProfile(ref);
    if (profile == null) {
      return const _ChildHomeData.empty();
    }
    final routines = await ref
        .read(routineRepositoryProvider)
        .routinesForProfile(profile.id);
    final now = habitarFunctionalDate();
    final sessionRepository = ref.read(routineSessionRepositoryProvider);
    final overrides = await ref
        .read(routineOverrideRepositoryProvider)
        .overridesForProfileDate(profileId: profile.id, date: now);
    final todaysRoutines = await routinesForToday(
      routines: routines,
      localDate: now,
      loadOverrides: () async => overrides,
      loadSessionToday: (routine) =>
          sessionRepository.latestSessionForRoutineDate(
        routineId: routine.metadata.id,
        localDate: now,
      ),
    );
    final scheduledRoutines = <Routine>[];
    for (final routine in routines) {
      if (routineAppliesOnDate(routine, now, overrides: overrides)) {
        scheduledRoutines.add(routine);
      }
    }
    final routine = todaysRoutines.isEmpty ? null : todaysRoutines.first;
    final steps = routine == null
        ? const <RoutineStep>[]
        : await ref
            .read(routineRepositoryProvider)
            .stepsForRoutine(routine.metadata.id);
    RoutineSession? session;
    if (routine != null) {
      session = await sessionRepository.activeSessionForRoutineToday(
        routineId: routine.metadata.id,
        localDate: now,
      );
    }
    final sessionsToday = await sessionRepository.sessionsForProfileDate(
      profileId: profile.id,
      localDate: now,
    );
    return _ChildHomeData(
      profile: profile,
      routine: routine,
      steps: steps,
      latestSession: session ?? _latestSession(sessionsToday),
      scheduledRoutineCount: scheduledRoutines.length,
      completedRoutineCount: sessionsToday
          .where((session) => session.status == RoutineSessionStatus.completed)
          .map((session) => session.routine.metadata.id)
          .toSet()
          .length,
      pendingRoutines: todaysRoutines,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: HabitarPage(
          maxWidth: 620,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          children: [
            const Center(child: HabitarLogo(size: 64)),
            const SizedBox(height: 20),
            FutureBuilder<_ChildHomeData>(
              future: _load(ref),
              key: ValueKey(ref.watch(currentProfileIdProvider)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? const _ChildHomeData.empty();
                final name = data.profile?.displayName ?? 'tu espacio';
                final firstStep =
                    data.steps.isEmpty ? null : data.steps.first.title;
                final completedToday = data.completedToday;
                final hasRoutinesToday = data.scheduledRoutineCount > 0;
                return Column(
                  children: [
                    Text('Hola, $name',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall),
                    Text('Tu día, a tu ritmo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: HabitarColors.primaryGreen)),
                    const SizedBox(height: 24),
                    _ChildPriorityCard(
                        color: HabitarColors.surfaceMist,
                        art: 'bag',
                        label: 'Ahora',
                        title: completedToday
                            ? 'Rutinas terminadas\npor hoy'
                            : data.routine?.title ??
                                (hasRoutinesToday
                                    ? 'Todo listo\npor hoy'
                                    : 'Sin rutina\npreparada'),
                        body: completedToday
                            ? 'Terminaste tus pasos de hoy. Cada paso cuenta.'
                            : firstStep == null
                                ? hasRoutinesToday
                                    ? 'No quedan pasos pendientes ahora.'
                                    : 'Un adulto puede preparar tus pasos.'
                                : 'Primer paso: $firstStep',
                        action: completedToday
                            ? 'Volver'
                            : data.routine == null
                                ? 'Volver'
                                : 'Empezar',
                        onTap: completedToday || data.routine == null
                            ? () => context.go('/profiles')
                            : () => _startRoutine(
                                  context,
                                  ref,
                                  data.routine!,
                                  data.steps,
                                )),
                    if (data.otherPendingRoutines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Más para hoy',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 10),
                      for (final routine in data.otherPendingRoutines) ...[
                        _ChildRoutineListTile(
                          routine: routine,
                          onTap: () => _startRoutineById(context, ref, routine),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 12),
                    _ChildPriorityCard(
                        color: HabitarColors.surfaceMist,
                        art: 'heart',
                        label: 'Pedir ayuda',
                        title: 'No tengo que\nhacerlo solo',
                        body: '',
                        action: 'Ayuda',
                        onTap: () => context.go('/child/emotions')),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Espacio adulto')),
          ],
        ),
      );
}

class _ChildHomeData {
  const _ChildHomeData({
    required this.profile,
    required this.routine,
    required this.steps,
    required this.latestSession,
    required this.scheduledRoutineCount,
    required this.completedRoutineCount,
    required this.pendingRoutines,
  });

  const _ChildHomeData.empty()
      : profile = null,
        routine = null,
        steps = const [],
        latestSession = null,
        scheduledRoutineCount = 0,
        completedRoutineCount = 0,
        pendingRoutines = const [];

  final SelectedHabitarProfile? profile;
  final Routine? routine;
  final List<RoutineStep> steps;
  final RoutineSession? latestSession;
  final int scheduledRoutineCount;
  final int completedRoutineCount;
  final List<Routine> pendingRoutines;

  bool get completedToday =>
      scheduledRoutineCount > 0 &&
      completedRoutineCount >= scheduledRoutineCount;

  /// Pending routines for today besides the one already highlighted in the
  /// "Ahora" card, in the same schedule order.
  List<Routine> get otherPendingRoutines =>
      pendingRoutines.length <= 1 ? const [] : pendingRoutines.skip(1).toList();
}

RoutineSession? _latestSession(List<RoutineSession> sessions) {
  if (sessions.isEmpty) {
    return null;
  }
  final sorted = [...sessions]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sorted.first;
}

bool _isOpenRoutineSession(RoutineSession session) {
  return session.status == RoutineSessionStatus.running ||
      session.status == RoutineSessionStatus.paused ||
      session.status == RoutineSessionStatus.postponed;
}

/// Loads a routine's steps on demand and starts it. Used by the "more for
/// today" list, where steps aren't preloaded for every pending routine.
Future<void> _startRoutineById(
  BuildContext context,
  WidgetRef ref,
  Routine routine,
) async {
  final steps = await ref
      .read(routineRepositoryProvider)
      .stepsForRoutine(routine.metadata.id);
  if (!context.mounted) {
    return;
  }
  await _startRoutine(context, ref, routine, steps);
}

Future<void> _startRoutine(
  BuildContext context,
  WidgetRef ref,
  Routine routine,
  List<RoutineStep> steps,
) async {
  final latestSession = await ref
      .read(routineSessionRepositoryProvider)
      .latestSessionForRoutineDate(
        routineId: routine.metadata.id,
        localDate: habitarFunctionalDate(),
      );
  if (latestSession?.status == RoutineSessionStatus.completed) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta rutina ya terminó por hoy.')),
      );
    }
    return;
  }
  if (latestSession != null && _isOpenRoutineSession(latestSession)) {
    ref.read(currentRoutineSessionIdProvider.notifier).state = latestSession.id;
    if (context.mounted) {
      context.go('/routine/player');
    }
    return;
  }

  if (steps.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta rutina todavía no tiene pasos preparados.'),
      ),
    );
    return;
  }

  RoutineSession session;
  try {
    session = await ref.read(routineServiceProvider).startExistingRoutine(
          routine,
          steps: steps,
        );
  } on StateError catch (error) {
    if (context.mounted) {
      final message = error.message == 'ROUTINE_ALREADY_COMPLETED_TODAY'
          ? 'Esta rutina ya termino por hoy.'
          : 'No pudimos iniciar la rutina.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    return;
  }
  ref.read(currentRoutineSessionIdProvider.notifier).state = session.id;
  if (context.mounted) {
    context.go('/routine/player');
  }
}

class _ChildPriorityCard extends StatelessWidget {
  const _ChildPriorityCard(
      {required this.color,
      required this.art,
      required this.label,
      required this.title,
      required this.body,
      required this.action,
      required this.onTap});
  final Color color;
  final String art;
  final String label;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HabitarCard(
        color: color,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  HabitarPill(
                      label: label, color: Colors.white.withValues(alpha: .5)),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(body, style: Theme.of(context).textTheme.bodyLarge)
                  ],
                ])),
            SizedBox(
                width: 130,
                height: 120,
                child: HabitarSoftIllustration(label: art)),
          ]),
          const SizedBox(height: 14),
          OutlinedButton(
              onPressed: onTap,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(action),
                    const SizedBox(width: 14),
                    const Icon(Icons.arrow_forward_rounded)
                  ])),
        ]),
      );
}

/// Simple row for a pending routine that isn't the highlighted "Ahora" one,
/// just enough to identify it and start it.
class _ChildRoutineListTile extends StatelessWidget {
  const _ChildRoutineListTile({required this.routine, required this.onTap});

  final Routine routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HabitarCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  routine.scheduledTimeLabel ?? 'Sin horario',
                  style: const TextStyle(color: HabitarColors.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onTap, child: const Text('Empezar')),
        ]),
      );
}

class TeenHomeScreen extends ConsumerWidget {
  const TeenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProfile = loadSelectedProfile(ref);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi espacio'), actions: [
        IconButton(
            tooltip: 'Privacidad',
            onPressed: () => context.go('/teen/privacy'),
            icon: const Icon(Icons.shield_outlined))
      ]),
      body: FutureBuilder(
        future: selectedProfile,
        builder: (context, snapshot) {
          final profileName = snapshot.data?.displayName ?? 'tu espacio';
          return HabitarPage(children: [
            Text('Buenas tardes, $profileName',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Tu día, a tu ritmo.',
                style: TextStyle(color: HabitarColors.mutedInk)),
            const SizedBox(height: 24),
            const _TeenTile(
                icon: Icons.flag_outlined,
                title: 'Objetivo de hoy',
                value: 'Sin objetivo cargado'),
            const _TeenTile(
                icon: Icons.task_alt_rounded,
                title: 'Hábitos activos',
                value: 'Sin hábitos cargados'),
            const _TeenTile(
                icon: Icons.insights_rounded,
                title: 'Mi progreso',
                value: 'Sin progreso registrado'),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () => context.go('/teen/reflection'),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Reflexión diaria')),
            TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Entrar al espacio adulto')),
          ]);
        },
      ),
    );
  }
}

class _TeenTile extends StatelessWidget {
  const _TeenTile(
      {required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HabitarCard(
            child: ListTile(
                leading: Icon(icon, color: HabitarColors.deepGreen),
                title: Text(title),
                subtitle: Text(value),
                trailing: const Icon(Icons.chevron_right))),
      );
}

class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen(
      {super.key,
      required this.title,
      required this.message,
      this.teen = false});
  final String title;
  final String message;
  final bool teen;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: HabitarPage(children: [
        EmptyState(
            icon: teen ? Icons.lock_person_outlined : Icons.star_rounded,
            title: title,
            message: message),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: () => context.pop(), child: const Text('Volver')),
      ]));
}

class AdultPinScreen extends StatelessWidget {
  const AdultPinScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Espacio adulto')),
        body: HabitarPage(children: [
          const EmptyState(
              icon: Icons.lock_outline,
              title: 'Verificar cuenta adulta',
              message:
                  'Las rutinas, hábitos y cambios familiares quedan protegidos.'),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Entrar como adulto')),
        ]),
      );
}

void showAdultPin(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verificar adulto'),
      content: const Text(
          'Para administrar rutinas, perfiles y recompensas, entrá con la cuenta adulta.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/login');
            },
            child: const Text('Entrar como adulto')),
      ],
    ),
  );
}
