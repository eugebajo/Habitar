import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

import '../../components/adult_shell.dart';
import '../../dependencies.dart';
import '../../local_restore.dart';
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
              padding: const EdgeInsets.all(22),
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
                _AdultTeamCard(hasProfile: data.profile != null),
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
    final routine = routines.isEmpty ? null : routines.first;
    final steps = routine == null
        ? const <RoutineStep>[]
        : await routineRepository.stepsForRoutine(routine.metadata.id);
    final latestSession =
        await ref.read(routineSessionRepositoryProvider).activeSessionForProfile(
              profile.id,
            );
    final todaySession =
        latestSession != null && _sameDay(latestSession.startedAt, DateTime.now())
            ? latestSession
            : null;
    final supportRequests =
        await ref.read(supportRequestRepositoryProvider).requestsForProfile(
              profile.id,
            );
    final overrides = await ref
        .read(routineOverrideRepositoryProvider)
        .overridesForProfileDate(profileId: profile.id, date: DateTime.now());

    assert(() {
      // Development-only diagnostics. Do not log tokens or secrets.
      // ignore: avoid_print
      print(
        'PROGRESS REFRESH: completed=${latestSession?.completedStepIds.length ?? 0} total=${steps.length}',
      );
      return true;
    }());

    return _DashboardData(
      profile: profile,
      routines: routines,
      currentRoutine: routine,
      currentSteps: steps,
      activeSession: todaySession,
      progressSession: latestSession,
      supportRequests: supportRequests,
      overridesToday: overrides,
    );
  }
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.profile});

  final SelectedHabitarProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const HabitarWordmark(),
        const Spacer(),
        InkWell(
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
                HabitarAvatar(label: profile?.displayName ?? 'Perfil', size: 38),
                const SizedBox(width: 8),
                Text(
                  profile?.displayName ?? 'Elegir perfil',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: HabitarColors.deepGreen,
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
    final routine = data.currentRoutine;
    final session = data.activeSession;
    final completed = session?.completedStepIds.length ?? 0;
    final total = data.currentSteps.length;
    final pending = total == 0 ? 0 : (total - completed).clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;
    final isCompleted = session?.status == RoutineSessionStatus.completed;
    final nextStep = isCompleted
        ? null
        : session?.activeStep ??
            (data.currentSteps.isEmpty ? null : data.currentSteps.first);

    return HabitarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const HabitarPill(
              icon: Icons.calendar_today_rounded,
              label: 'Hoy',
            ),
            const Spacer(),
            HabitarPill(
              label: profile == null
                  ? 'Sin perfil'
                  : routine == null
                      ? 'Sin rutinas'
                      : isCompleted
                          ? 'Rutina completada'
                      : '$pending de $total pendientes',
              color: HabitarColors.surfaceWarm,
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            routine?.title ?? 'Todavía no hay rutinas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          if (routine == null)
            Text(
              profile == null
                  ? 'Elegí un perfil para ver su día real.'
                  : 'Creá una rutina para este perfil y aparecerá acá.',
              style: const TextStyle(color: HabitarColors.mutedInk),
            )
          else ...[
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: HabitarColors.surfaceMist,
                    color: HabitarColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text('${(progress * 100).round()}% completado'),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HabitarColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(children: [
                const SizedBox(
                  width: 90,
                  height: 90,
                  child: HabitarSoftIllustration(label: 'bag'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? 'Listo por hoy' : 'Siguiente paso',
                        style:
                            const TextStyle(color: HabitarColors.mutedInk),
                      ),
                      Text(
                        isCompleted
                            ? 'Rutina completada'
                            : nextStep?.title ?? 'Sin pasos cargados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: HabitarColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(routine.scheduledTimeLabel ?? 'Sin horario'),
                      ]),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _sendRoutineSignal(context, ref),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Recordar'),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendRoutineSignal(BuildContext context, WidgetRef ref) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      context.go('/profiles');
      return;
    }
    final routines =
        await ref.read(routineRepositoryProvider).routinesForProfile(profileId);
    if (!context.mounted) return;
    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero prepará una rutina para este perfil.'),
        ),
      );
      return;
    }
    final routine = routines.first;
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
    final total = data.currentSteps.length;
    final completed = data.progressSession?.completedStepIds.length ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    return HabitarCard(
      child: Row(children: [
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
                '${data.routines.length} rutinas creadas · ${data.overridesToday.length} ajustes hoy',
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/progress'),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Reporte PDF'),
        ),
      ]),
    );
  }
}

class _AdultTeamCard extends ConsumerWidget {
  const _AdultTeamCard({required this.hasProfile});

  final bool hasProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final profileId = ref.watch(currentProfileIdProvider);
    if (!hasProfile || familyId == null || profileId == null) {
      return HabitarCard(
        child: ListTile(
          leading:
              const Icon(Icons.groups_rounded, color: HabitarColors.primaryGreen),
          title: const Text('Equipo adulto'),
          subtitle: const Text('Elegí un perfil para sumar acompañantes.'),
          trailing: TextButton(
            onPressed: () => context.go('/profiles'),
            child: const Text('Perfiles'),
          ),
        ),
      );
    }
    return FutureBuilder<_AdultTeamData>(
      future: _loadTeam(ref, familyId, profileId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _AdultTeamData.empty();
        return HabitarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                Wrap(spacing: 8, runSpacing: 8, children: [
                  TextButton.icon(
                    onPressed: () => _showInviteAdultDialog(
                      context: context,
                      ref: ref,
                      familyId: familyId,
                    ),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Invitar'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddAdultDialog(
                      context: context,
                      ref: ref,
                      familyId: familyId,
                      profileId: profileId,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Acompañante'),
                  ),
                ]),
              ]),
              const SizedBox(height: 8),
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: HabitarColors.surfaceWarm,
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          color: HabitarColors.deepGreen,
                        ),
                      ),
                      title: Text(invitation.email),
                      subtitle: Text(_familyMemberRoleLabel(invitation.role)),
                    ),
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
                    title: Text(adult.displayName),
                    subtitle: Text([
                      adult.roleLabel ?? _adultKindLabel(adult.kind),
                      if (adult.email != null && adult.email!.isNotEmpty)
                        adult.email!,
                    ].join(' - ')),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<_AdultTeamData> _loadTeam(
    WidgetRef ref,
    String familyId,
    String profileId,
  ) async {
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
    required WidgetRef ref,
    required String familyId,
  }) async {
    final emailController = TextEditingController();
    var role = FamilyMemberRole.parent;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invitar adulto'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
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
                onChanged: (value) {
                  if (value != null) setDialogState(() => role = value);
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
                final email = emailController.text.trim();
                if (!email.contains('@')) return;
                try {
                  final user =
                      await ref.read(authRepositoryProvider).currentUser();
                  if (user == null) {
                    throw StateError('No active adult session.');
                  }
                  await ref.read(familyRepositoryProvider).createAdultInvitation(
                        familyId: familyId,
                        email: email,
                        role: role,
                        invitedByUserId: user.metadata.id,
                      );
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No pudimos crear la invitacion. Revisa tu acceso e intenta de nuevo.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAdultDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String familyId,
    required String profileId,
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
    required this.routines,
    required this.currentRoutine,
    required this.currentSteps,
    required this.activeSession,
    required this.progressSession,
    required this.supportRequests,
    required this.overridesToday,
  });

  const _DashboardData.empty()
      : profile = null,
        routines = const [],
        currentRoutine = null,
        currentSteps = const [],
        activeSession = null,
        progressSession = null,
        supportRequests = const [],
        overridesToday = const [];

  final SelectedHabitarProfile? profile;
  final List<Routine> routines;
  final Routine? currentRoutine;
  final List<RoutineStep> currentSteps;
  final RoutineSession? activeSession;
  final RoutineSession? progressSession;
  final List<SupportRequest> supportRequests;
  final List<RoutineOverride> overridesToday;
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
