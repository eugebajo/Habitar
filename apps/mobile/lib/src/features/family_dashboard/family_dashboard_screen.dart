import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:share_plus/share_plus.dart';

import '../../components/adult_shell.dart';
import '../../dependencies.dart';
import '../../local_restore.dart';
import '../../routine_today.dart';
import '../../selected_profile.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(currentProfileIdProvider);
    final familyId = ref.watch(currentFamilyIdProvider);
    return AdultShell(
      child: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _loadDashboard(ref),
          key: ValueKey('$familyId-$profileId'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? const _DashboardData.empty();
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 132),
              children: [
                _DashboardHeader(profile: data.profile),
                const SizedBox(height: 28),
                Text(
                  'Hola,\n¿qué necesita tu familia hoy?',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 22),
                _TodayCard(data: data),
                const SizedBox(height: 24),
                Text(
                  'Qué necesita mi atención',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _AttentionList(requests: data.supportRequests),
                const SizedBox(height: 24),
                _ProgressCard(data: data),
                const SizedBox(height: 18),
                _AdultTeamCard(
                  hasProfile: data.profile != null,
                  profileName: data.profile?.displayName,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: data.profile == null
                      ? () => context.go('/profiles')
                      : () => context.go(
                            data.profile!.kind == ProfileKind.teen
                                ? '/teen'
                                : '/child',
                          ),
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Abrir espacio personal'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<_DashboardData> _loadDashboard(WidgetRef ref) async {
    final profile = await loadSelectedProfile(ref);
    if (profile == null) {
      return const _DashboardData.empty();
    }

    final routineRepository = ref.read(routineRepositoryProvider);
    final routines = await routineRepository.routinesForProfile(profile.id);
    final now = habitarFunctionalDate();
    final sessionRepository = ref.read(routineSessionRepositoryProvider);
    final overrideRepository = ref.read(routineOverrideRepositoryProvider);
    final overrides = await overrideRepository.overridesForProfileDate(
      profileId: profile.id,
      date: now,
    );
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
    final routineItems = <_RoutineDayItem>[];
    for (final routine in todaysRoutines) {
      final steps =
          await routineRepository.stepsForRoutine(routine.metadata.id);
      final session = await sessionRepository.activeSessionForRoutineToday(
        routineId: routine.metadata.id,
        localDate: now,
      );
      routineItems.add(_RoutineDayItem(
        routine: routine,
        steps: steps,
        session: session,
      ));
    }
    final sessionsToday = await sessionRepository.sessionsForProfileDate(
      profileId: profile.id,
      localDate: now,
    );
    final totalScheduledSteps =
        await _totalStepsFor(routineRepository, scheduledRoutines);
    final supportRequests =
        await ref.read(supportRequestRepositoryProvider).requestsForProfile(
              profile.id,
            );

    assert(() {
      // Development-only diagnostics. Do not log tokens or secrets.
      // ignore: avoid_print
      print(
        'PROGRESS REFRESH: completed=${_completedSteps(sessionsToday)} total=$totalScheduledSteps',
      );
      return true;
    }());

    return _DashboardData(
      profile: profile,
      scheduledRoutines: scheduledRoutines,
      routineItems: routineItems,
      sessionsToday: sessionsToday,
      totalScheduledSteps: totalScheduledSteps,
      supportRequests: supportRequests,
      overridesToday: overrides,
    );
  }
}

Future<int> _totalStepsFor(
  RoutineRepository repository,
  List<Routine> routines,
) async {
  var total = 0;
  for (final routine in routines) {
    total += (await repository.stepsForRoutine(routine.metadata.id)).length;
  }
  return total;
}

int _completedSteps(List<RoutineSession> sessions) => sessions.fold<int>(
      0,
      (total, session) =>
          total +
          session.completedStepIds.length +
          session.skippedStepIds.length,
    );

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.profile});

  final SelectedHabitarProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: HabitarWordmark(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => context.go('/profiles'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: HabitarColors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: HabitarColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HabitarAvatar(
                      label: profile?.displayName ?? 'Perfil', size: 38),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      profile?.displayName ?? 'Elegir perfil',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: HabitarColors.deepGreen,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: HabitarColors.deepGreen,
                  ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            if (value == 'settings') context.go('/settings');
            if (value == 'logout') _signOut(context, ref);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'settings', child: Text('Configuración')),
            PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
          ],
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionServiceProvider).signOut();
    ref.read(currentFamilyIdProvider.notifier).state = null;
    ref.read(currentProfileIdProvider.notifier).state = null;
    ref.read(currentProfileKindProvider.notifier).state = null;
    ref.read(currentRoutineSessionIdProvider.notifier).state = null;
    ref.invalidate(appRestoreProvider);
    if (context.mounted) context.go('/onboarding');
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = data.profile;
    final items = data.routineItems;
    final completedRoutineIds = data.sessionsToday
        .where((session) => session.status == RoutineSessionStatus.completed)
        .map((session) => session.routine.metadata.id)
        .toSet();
    final allScheduledCompleted = data.scheduledRoutines.isNotEmpty &&
        items.isEmpty &&
        completedRoutineIds.isNotEmpty;
    final totalPendingSteps = items.fold<int>(
      0,
      (total, item) => total + item.pendingStepCount,
    );
    final statusLabel = profile == null
        ? 'Sin perfil'
        : allScheduledCompleted
            ? 'Todo completado'
            : items.isEmpty
                ? 'Sin rutinas'
                : items.length == 1
                    ? '$totalPendingSteps pendientes'
                    : '${items.length} rutinas - $totalPendingSteps pendientes';

    return HabitarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const HabitarPill(
                icon: Icons.calendar_today_rounded,
                label: 'Hoy',
              ),
              HabitarPill(
                label: statusLabel,
                color: HabitarColors.surfaceWarm,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            items.isEmpty
                ? (allScheduledCompleted
                    ? 'Rutinas completadas'
                    : 'Todavía no hay rutinas')
                : 'Rutinas de hoy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              profile == null
                  ? 'Elegí un perfil para ver su día real.'
                  : allScheduledCompleted
                      ? 'Las rutinas de hoy ya quedaron listas.'
                      : 'Creá una rutina para este perfil y aparecerá acá.',
              style: const TextStyle(color: HabitarColors.mutedInk),
            )
          else
            for (final item in items) ...[
              _RoutineDayRow(
                item: item,
                onRemind: () => _sendRoutineSignal(context, ref, item.routine),
              ),
              if (item != items.last) const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }

  Future<void> _sendRoutineSignal(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      context.go('/profiles');
      return;
    }
    final steps = await ref
        .read(routineRepositoryProvider)
        .stepsForRoutine(routine.metadata.id);
    if (!context.mounted) return;
    final plan = await ref.read(notificationServiceProvider).sendRoutineSignal(
          profileId: profileId,
          routineId: routine.metadata.id,
          routineTitle: routine.title,
          firstStepTitle: steps.isEmpty ? 'Empezar' : steps.first.title,
          sentByAdultId: ref.read(currentFamilyIdProvider) ?? 'adult-local',
          sentByName: 'Adulto',
          kind: routine.silentNotification
              ? RoutineSignalKind.silentNotice
              : RoutineSignalKind.softVibration,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          plan.isBlocked ? plan.blockedReason! : 'Señal enviada con suavidad.',
        ),
      ),
    );
  }
}

/// One routine's progress for today, with its own progress bar, next step
/// and reminder action — so a profile with several pending routines shows
/// all of them, not just the earliest one.
class _RoutineDayRow extends StatelessWidget {
  const _RoutineDayRow({required this.item, required this.onRemind});

  final _RoutineDayItem item;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final routine = item.routine;
    final progress = item.progress;
    final isCompleted = item.session?.status == RoutineSessionStatus.completed;
    final nextStep = isCompleted ? null : item.nextStep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HabitarColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(routine.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: HabitarColors.surfaceMist,
                        color: HabitarColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(progress * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isCompleted
                    ? 'Rutina completada'
                    : nextStep?.title ?? 'Sin pasos cargados',
                style: const TextStyle(color: HabitarColors.mutedInk),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: HabitarColors.primaryGreen,
                  ),
                  Text(routine.scheduledTimeLabel ?? 'Sin horario'),
                ],
              ),
            ],
          );
          final reminderButton = OutlinedButton.icon(
            onPressed: onRemind,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Recordar'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: reminderButton),
              ],
            );
          }
          return Row(children: [
            Expanded(child: textBlock),
            const SizedBox(width: 12),
            reminderButton,
          ]);
        },
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.requests});

  final List<SupportRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const HabitarCard(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay pedidos de ayuda o pausa pendientes.',
          style: TextStyle(color: HabitarColors.mutedInk),
        ),
      );
    }
    return Column(
      children: [
        for (final request in requests.take(3)) ...[
          _AttentionTile(request: request),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.request});

  final SupportRequest request;

  @override
  Widget build(BuildContext context) {
    final isPause = request.kind == 'pause' || request.note == 'Pausa';
    final isExtraTime = request.kind == 'extra_time';
    final color = isPause
        ? HabitarColors.warmGold
        : isExtraTime
            ? HabitarColors.primaryGreen
            : HabitarColors.supportRose;
    final icon = isPause
        ? Icons.pause_rounded
        : isExtraTime
            ? Icons.schedule_rounded
            : Icons.pan_tool_alt_rounded;
    final title = isPause
        ? 'Pausa solicitada'
        : isExtraTime
            ? 'Más tiempo solicitado'
            : 'Ayuda solicitada';
    final message = isPause
        ? 'Necesita una pausa para seguir con calma.'
        : isExtraTime
            ? 'Pidió un poco más de tiempo para este paso.'
            : 'Necesita acompañamiento en este momento.';
    return HabitarCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .18),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(message),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: HabitarColors.deepGreen),
      ]),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalScheduledSteps;
    final completed =
        total == 0 ? 0 : _completedSteps(data.sessionsToday).clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;
    return HabitarCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 470) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProgressRing(value: progress, size: 86),
                const SizedBox(height: 14),
                Text(
                  'Resumen semanal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Datos reales del perfil seleccionado',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HabitarColors.mutedInk),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Sin progreso registrado'
                      : '$completed de $total pasos completados',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${data.scheduledRoutines.length} rutinas hoy - ${data.overridesToday.length} ajustes hoy',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/progress'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Reporte PDF'),
                ),
              ],
            );
          }
          return Row(children: [
            ProgressRing(value: progress, size: 86),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen semanal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    'Datos reales del perfil seleccionado',
                    style: TextStyle(color: HabitarColors.mutedInk),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    total == 0
                        ? 'Sin progreso registrado'
                        : '$completed de $total pasos completados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${data.scheduledRoutines.length} rutinas hoy - ${data.overridesToday.length} ajustes hoy',
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/progress'),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Reporte PDF'),
            ),
          ]);
        },
      ),
    );
  }
}

class _AdultTeamCard extends ConsumerStatefulWidget {
  const _AdultTeamCard({required this.hasProfile, this.profileName});

  final bool hasProfile;
  final String? profileName;

  @override
  ConsumerState<_AdultTeamCard> createState() => _AdultTeamCardState();
}

class _AdultTeamCardState extends ConsumerState<_AdultTeamCard> {
  Future<_AdultTeamData>? _future;
  String? _loadedFamilyId;
  String? _loadedProfileId;

  void _refresh(String familyId, String profileId) {
    setState(() {
      _future = _loadTeam(familyId, profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final profileId = ref.watch(currentProfileIdProvider);
    if (!widget.hasProfile || familyId == null || profileId == null) {
      return HabitarCard(
        child: ListTile(
          leading: const Icon(Icons.groups_rounded,
              color: HabitarColors.primaryGreen),
          title: const Text('Equipo adulto'),
          subtitle: const Text('Elegí un perfil para sumar acompañantes.'),
          trailing: TextButton(
            onPressed: () => context.go('/profiles'),
            child: const Text('Perfiles'),
          ),
        ),
      );
    }
    if (_future == null ||
        _loadedFamilyId != familyId ||
        _loadedProfileId != profileId) {
      _loadedFamilyId = familyId;
      _loadedProfileId = profileId;
      _future = _loadTeam(familyId, profileId);
    }
    return FutureBuilder<_AdultTeamData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _AdultTeamData.empty();
        return HabitarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.groups_rounded,
                      color: HabitarColors.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Equipo adulto',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  TextButton.icon(
                    onPressed: () => _showInviteAdultDialog(
                      context: context,
                      familyId: familyId,
                      profileName: widget.profileName,
                      onCreated: () => _refresh(familyId, profileId),
                    ),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Invitar'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddAdultDialog(
                      context: context,
                      familyId: familyId,
                      profileId: profileId,
                      onAdded: () => _refresh(familyId, profileId),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Acompañante'),
                  ),
                ]),
              ]),
              const SizedBox(height: 10),
              if (data.members.isEmpty && data.adults.isEmpty)
                const Text(
                  'Sumá madres, padres, cuidadores, docentes o profesionales vinculados a este perfil.',
                  style: TextStyle(color: HabitarColors.mutedInk),
                )
              else ...[
                if (data.members.isNotEmpty) ...[
                  const Text(
                    'Acceso familiar',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: HabitarColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final member in data.members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: HabitarColors.surfaceMist,
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: HabitarColors.deepGreen,
                        ),
                      ),
                      title: Text(
                        member.displayName ??
                            member.email ??
                            'Adulto con acceso',
                        softWrap: true,
                      ),
                      subtitle: Text(_familyMemberRoleLabel(member.role)),
                    ),
                ],
                if (data.invitations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Invitaciones pendientes',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: HabitarColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final invitation in data.invitations)
                    _InvitationRow(invitation: invitation),
                ],
                if (data.adults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Acompañantes de este perfil',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: HabitarColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                for (final adult in data.adults)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: HabitarAvatar(
                      label: adult.displayName,
                      size: 42,
                      color: HabitarColors.surfaceMist,
                    ),
                    title: Text(adult.displayName, softWrap: true),
                    subtitle: Text(
                      [
                        adult.roleLabel ?? _adultKindLabel(adult.kind),
                        if (adult.email != null && adult.email!.isNotEmpty)
                          adult.email!,
                      ].join(' - '),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<_AdultTeamData> _loadTeam(String familyId, String profileId) async {
    final familyRepository = ref.read(familyRepositoryProvider);
    final members = await familyRepository.membersForFamily(familyId);
    final invitations = await familyRepository.invitationsForFamily(familyId);
    final adults =
        await ref.read(adultProfileServiceProvider).adultProfilesForProfile(
              profileId,
            );
    return _AdultTeamData(
      members: members,
      invitations: invitations
          .where((item) => item.status == AdultInvitationStatus.pending)
          .toList(growable: false),
      adults: adults,
    );
  }

  Future<void> _showInviteAdultDialog({
    required BuildContext context,
    required String familyId,
    required String? profileName,
    required VoidCallback onCreated,
  }) async {
    final emailController = TextEditingController();
    var role = FamilyMemberRole.parent;
    var isSubmitting = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invitar adulto'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'Vamos a generar un código para compartir por WhatsApp. '
                'Quien lo use se suma a esta familia.',
                style: TextStyle(color: HabitarColors.mutedInk),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Correo de quien invitás',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FamilyMemberRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  FamilyMemberRole.parent,
                  FamilyMemberRole.caregiver,
                  FamilyMemberRole.professional,
                  FamilyMemberRole.viewer,
                ]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_familyMemberRoleLabel(value)),
                        ))
                    .toList(growable: false),
                onChanged: isSubmitting
                    ? null
                    : (value) {
                        if (value != null) setDialogState(() => role = value);
                      },
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!,
                    style: const TextStyle(color: HabitarColors.supportRose)),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (!email.contains('@')) {
                        setDialogState(
                            () => error = 'Ingresá un correo válido.');
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        error = null;
                      });
                      InvitationCodeCreated created;
                      try {
                        final user = await ref
                            .read(authRepositoryProvider)
                            .currentUser();
                        if (user == null) {
                          throw StateError('No active adult session.');
                        }
                        created = await ref
                            .read(familyRepositoryProvider)
                            .createInvitationWithCode(
                              familyId: familyId,
                              email: email,
                              role: role,
                              invitedByUserId: user.metadata.id,
                              invitedByUserEmail: user.email,
                            );
                      } on FamilyInvitationException catch (invitationError) {
                        setDialogState(() {
                          isSubmitting = false;
                          error = _invitationErrorMessage(invitationError.code);
                        });
                        return;
                      } catch (_) {
                        setDialogState(() {
                          isSubmitting = false;
                          error =
                              'No pudimos crear la invitación. Intentá nuevamente.';
                        });
                        return;
                      }
                      onCreated();
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        await _showInvitationCodeCard(
                          context: context,
                          created: created,
                          profileName: profileName,
                        );
                      }
                    },
              child: Text(isSubmitting ? 'Generando...' : 'Generar código'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInvitationCodeCard({
    required BuildContext context,
    required InvitationCodeCreated created,
    required String? profileName,
  }) async {
    final message = 'Te invito a acompañar las rutinas de '
        '${profileName ?? 'nuestra familia'} en Habitar. '
        'Descargá la app y usá este código: ${created.code}';
    var copied = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Código generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Compartilo por WhatsApp. Vale por 7 días y se puede usar una sola vez.',
                style: TextStyle(color: HabitarColors.mutedInk),
              ),
              const SizedBox(height: 14),
              SelectableText(
                created.code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: created.code));
                      setDialogState(() => copied = true);
                    },
                    icon:
                        Icon(copied ? Icons.check_rounded : Icons.copy_rounded),
                    label: Text(copied ? 'Copiado' : 'Copiar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        Share.share(message, subject: 'Invitación a Habitar'),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir'),
                  ),
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAdultDialog({
    required BuildContext context,
    required String familyId,
    required String profileId,
    required VoidCallback onAdded,
  }) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    var kind = AdultProfileKind.parent;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar adulto'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo opcional'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdultProfileKind>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: AdultProfileKind.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_adultKindLabel(value)),
                        ))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setDialogState(() => kind = value);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await ref.read(adultProfileServiceProvider).createAdultProfile(
                      CreateAdultProfileInput(
                        familyId: familyId,
                        profileId: profileId,
                        displayName: name,
                        kind: kind,
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                      ),
                    );
                ref.invalidate(adultProfileServiceProvider);
                onAdded();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.profile,
    required this.scheduledRoutines,
    required this.routineItems,
    required this.sessionsToday,
    required this.totalScheduledSteps,
    required this.supportRequests,
    required this.overridesToday,
  });

  const _DashboardData.empty()
      : profile = null,
        scheduledRoutines = const [],
        routineItems = const [],
        sessionsToday = const [],
        totalScheduledSteps = 0,
        supportRequests = const [],
        overridesToday = const [];

  final SelectedHabitarProfile? profile;
  final List<Routine> scheduledRoutines;
  final List<_RoutineDayItem> routineItems;
  final List<RoutineSession> sessionsToday;
  final int totalScheduledSteps;
  final List<SupportRequest> supportRequests;
  final List<RoutineOverride> overridesToday;
}

/// A single pending routine for today, together with its steps and its
/// session (if one was already started), so each row in the "today" list
/// can show its own progress independently.
class _RoutineDayItem {
  const _RoutineDayItem({
    required this.routine,
    required this.steps,
    required this.session,
  });

  final Routine routine;
  final List<RoutineStep> steps;
  final RoutineSession? session;

  int get completedStepCount => session?.completedStepIds.length ?? 0;
  int get totalStepCount => steps.length;
  int get pendingStepCount =>
      (totalStepCount - completedStepCount).clamp(0, totalStepCount);
  double get progress =>
      totalStepCount == 0 ? 0.0 : completedStepCount / totalStepCount;
  RoutineStep? get nextStep =>
      session?.activeStep ?? (steps.isEmpty ? null : steps.first);
}

class _AdultTeamData {
  const _AdultTeamData({
    required this.members,
    required this.invitations,
    required this.adults,
  });

  const _AdultTeamData.empty()
      : members = const [],
        invitations = const [],
        adults = const [];

  final List<FamilyMember> members;
  final List<AdultInvitation> invitations;
  final List<AdultProfile> adults;
}

/// One "Invitaciones pendientes" row. Keeps its own local copy of the
/// invitation so cancelling updates its displayed status immediately,
/// without needing the ancestor FutureBuilder (built from a fresh
/// `_loadTeam` future on every rebuild) to reload first.
class _InvitationRow extends ConsumerStatefulWidget {
  const _InvitationRow({required this.invitation});

  final AdultInvitation invitation;

  @override
  ConsumerState<_InvitationRow> createState() => _InvitationRowState();
}

class _InvitationRowState extends ConsumerState<_InvitationRow> {
  late AdultInvitation _invitation;
  var _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _invitation = widget.invitation;
  }

  bool get _canCancel =>
      _invitation.status == AdultInvitationStatus.pending &&
      _invitation.expiresAt.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: HabitarColors.surfaceWarm,
        child: Icon(
          _canCancel
              ? Icons.mark_email_unread_outlined
              : Icons.mail_outline_rounded,
          color: HabitarColors.deepGreen,
        ),
      ),
      title: Text(
        _invitation.email,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      subtitle: Text(
        '${_familyMemberRoleLabel(_invitation.role)} · ${_invitationStatusLabel(_invitation)}',
      ),
      trailing: _canCancel
          ? TextButton(
              onPressed: _isCanceling ? null : _cancel,
              child: Text(_isCanceling ? 'Cancelando...' : 'Cancelar'),
            )
          : null,
    );
  }

  Future<void> _cancel() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (user == null) return;
    setState(() => _isCanceling = true);
    try {
      await ref.read(familyRepositoryProvider).cancelInvitation(
            invitationId: _invitation.metadata.id,
            userId: user.metadata.id,
          );
      if (!mounted) return;
      setState(() {
        _invitation = AdultInvitation(
          metadata: _invitation.metadata,
          familyId: _invitation.familyId,
          email: _invitation.email,
          role: _invitation.role,
          status: AdultInvitationStatus.canceled,
          expiresAt: _invitation.expiresAt,
          invitedByUserId: _invitation.invitedByUserId,
          acceptedByUserId: _invitation.acceptedByUserId,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos cancelar la invitación. Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }
}

String _invitationStatusLabel(AdultInvitation invitation) {
  if (invitation.status == AdultInvitationStatus.pending &&
      invitation.expiresAt.isBefore(DateTime.now())) {
    return 'Vencida';
  }
  return switch (invitation.status) {
    AdultInvitationStatus.pending => 'Pendiente',
    AdultInvitationStatus.accepted => 'Aceptada',
    AdultInvitationStatus.revoked => 'Revocada',
    AdultInvitationStatus.expired => 'Vencida',
    AdultInvitationStatus.canceled => 'Cancelada',
  };
}

String _invitationErrorMessage(String code) {
  return switch (code) {
    'INVITATION_SELF_FORBIDDEN' => 'No podés invitarte a vos misma/o.',
    'INVITATION_ALREADY_PENDING' =>
      'Ya hay una invitación pendiente para ese correo en esta familia.',
    'INVITATION_ROLE_INVALID' => 'Elegí un rol válido.',
    'INVITATION_EMAIL_INVALID' => 'Ingresá un correo válido.',
    'INVITATION_CREATE_FORBIDDEN' =>
      'No tenés permiso para invitar en esta familia.',
    _ => 'No pudimos crear la invitación. Intentá nuevamente.',
  };
}

String _adultKindLabel(AdultProfileKind kind) {
  return switch (kind) {
    AdultProfileKind.parent => 'Madre, padre o tutor',
    AdultProfileKind.caregiver => 'Cuidador',
    AdultProfileKind.professional => 'Profesional',
    AdultProfileKind.teacher => 'Docente',
  };
}

String _familyMemberRoleLabel(FamilyMemberRole role) {
  return switch (role) {
    FamilyMemberRole.owner => 'Administradora',
    FamilyMemberRole.parent => 'Madre, padre o tutor',
    FamilyMemberRole.caregiver => 'Cuidador',
    FamilyMemberRole.professional => 'Profesional',
    FamilyMemberRole.viewer => 'Solo lectura',
  };
}
