import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';

import '../../components/adult_shell.dart';
import '../../dependencies.dart';
import '../../local_restore.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileIdProvider);
    final hasProfile = profile != null;
    return AdultShell(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                const HabitarWordmark(),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => context.go('/profiles'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: HabitarColors.card,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: HabitarColors.line),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HabitarAvatar(label: 'Tomi', size: 38),
                        SizedBox(width: 8),
                        Text('Tomi',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: HabitarColors.deepGreen)),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: HabitarColors.deepGreen),
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
                    PopupMenuItem(
                        value: 'settings', child: Text('Configuración')),
                    PopupMenuItem(
                        value: 'logout', child: Text('Cerrar sesión')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Hola,\n¿qué necesita tu familia hoy?',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 22),
            HabitarCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const HabitarPill(
                        icon: Icons.calendar_today_rounded, label: 'Hoy'),
                    const Spacer(),
                    HabitarPill(
                      label: hasProfile ? '2 de 4 pendientes' : 'Sin perfil',
                      color: HabitarColors.surfaceWarm,
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text('Después de la escuela',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: hasProfile ? .5 : 0,
                          minHeight: 10,
                          backgroundColor: HabitarColors.surfaceMist,
                          color: HabitarColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(hasProfile ? '50% completado' : 'Elegí un perfil'),
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
                          child: HabitarSoftIllustration(label: 'bag')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Siguiente paso',
                                style:
                                    TextStyle(color: HabitarColors.mutedInk)),
                            Text('Preparar la mochila',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            const Row(children: [
                              Icon(Icons.schedule_rounded,
                                  size: 18, color: HabitarColors.primaryGreen),
                              SizedBox(width: 6),
                              Text('18:30'),
                            ]),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: hasProfile
                            ? () => _sendRoutineSignal(context, ref)
                            : () => context.go('/profiles'),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Recordar'),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Qué necesita mi atención',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _AttentionTile(
                icon: Icons.pause_rounded,
                color: HabitarColors.warmGold,
                title: 'Pausa solicitada',
                body: 'Tomi pidió una pausa en “Hacer la tarea”.'),
            const SizedBox(height: 10),
            const _AttentionTile(
                icon: Icons.pan_tool_alt_rounded,
                color: HabitarColors.supportRose,
                title: 'Ayuda solicitada',
                body: 'Tomi necesita ayuda en “Leer”.'),
            const SizedBox(height: 10),
            const _AttentionTile(
                icon: Icons.warning_amber_rounded,
                color: HabitarColors.danger,
                title: 'Rutina no iniciada',
                body: '“Prepararse para dormir” aún no fue iniciada.'),
            const SizedBox(height: 24),
            HabitarCard(
              child: Row(children: [
                const ProgressRing(value: .72, size: 86),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen semanal',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Text('5 - 11 de mayo',
                            style: TextStyle(color: HabitarColors.mutedInk)),
                        const SizedBox(height: 8),
                        Text('Rutinas completadas',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Text('¡Vas por buen camino!'),
                      ]),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/progress'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Reporte PDF'),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            _AdultTeamCard(hasProfile: hasProfile),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => context.go(
                  ref.read(currentProfileKindProvider) == ProfileKind.teen
                      ? '/teen'
                      : '/child'),
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('Abrir espacio personal'),
            ),
          ],
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Primero prepará una rutina para este perfil.')));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(plan.isBlocked
            ? plan.blockedReason!
            : 'Señal enviada con suavidad.')));
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

class _AttentionTile extends StatelessWidget {
  const _AttentionTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => HabitarCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: color.withValues(alpha: .18),
              child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(body)
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: HabitarColors.deepGreen),
        ]),
      );
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
          leading: const Icon(Icons.groups_rounded,
              color: HabitarColors.primaryGreen),
          title: const Text('Equipo adulto'),
          subtitle: const Text('Elegí un perfil para sumar acompañantes.'),
          trailing: TextButton(
              onPressed: () => context.go('/profiles'),
              child: const Text('Perfiles')),
        ),
      );
    }
    return FutureBuilder<_AdultTeamData>(
      future: _loadTeam(ref, familyId, profileId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _AdultTeamData.empty();
        return HabitarCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.groups_rounded,
                  color: HabitarColors.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Equipo adulto',
                      style: Theme.of(context).textTheme.titleMedium)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                TextButton.icon(
                  onPressed: () => _showInviteAdultDialog(
                      context: context, ref: ref, familyId: familyId),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Invitar'),
                ),
                TextButton.icon(
                  onPressed: () => _showAddAdultDialog(
                      context: context,
                      ref: ref,
                      familyId: familyId,
                      profileId: profileId),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Acompañante'),
                ),
              ]),
            ]),
            const SizedBox(height: 8),
            if (data.members.isEmpty && data.adults.isEmpty)
              const Text(
                  'Sumá madres, padres, cuidadores, docentes o profesionales vinculados a este perfil.',
                  style: TextStyle(color: HabitarColors.mutedInk))
            else ...[
              if (data.members.isNotEmpty) ...[
                const Text('Acceso familiar',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: HabitarColors.deepGreen)),
                const SizedBox(height: 6),
                for (final member in data.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: HabitarColors.surfaceMist,
                      child: Icon(Icons.verified_user_outlined,
                          color: HabitarColors.deepGreen),
                    ),
                    title: Text(member.displayName ??
                        member.email ??
                        'Adulto con acceso'),
                    subtitle: Text(_familyMemberRoleLabel(member.role)),
                  ),
              ],
              if (data.invitations.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Invitaciones pendientes',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: HabitarColors.deepGreen)),
                const SizedBox(height: 6),
                for (final invitation in data.invitations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: HabitarColors.surfaceWarm,
                      child: Icon(Icons.mark_email_unread_outlined,
                          color: HabitarColors.deepGreen),
                    ),
                    title: Text(invitation.email),
                    subtitle: Text(_familyMemberRoleLabel(invitation.role)),
                  ),
              ],
              if (data.adults.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Acompañantes de este perfil',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: HabitarColors.deepGreen)),
                const SizedBox(height: 6),
              ],
              for (final adult in data.adults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: HabitarAvatar(
                      label: adult.displayName,
                      size: 42,
                      color: HabitarColors.surfaceMist),
                  title: Text(adult.displayName),
                  subtitle: Text([
                    adult.roleLabel ?? _adultKindLabel(adult.kind),
                    if (adult.email != null && adult.email!.isNotEmpty)
                      adult.email!
                  ].join(' - ')),
                ),
            ],
          ]),
        );
      },
    );
  }

  Future<_AdultTeamData> _loadTeam(
      WidgetRef ref, String familyId, String profileId) async {
    final familyRepository = ref.read(familyRepositoryProvider);
    final members = await familyRepository.membersForFamily(familyId);
    final invitations = await familyRepository.invitationsForFamily(familyId);
    final adults = await ref
        .read(adultProfileServiceProvider)
        .adultProfilesForProfile(profileId);
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
                        child: Text(_familyMemberRoleLabel(value))))
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
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (!email.contains('@')) return;
                final user =
                    await ref.read(authRepositoryProvider).currentUser();
                await ref.read(familyRepositoryProvider).createAdultInvitation(
                      familyId: familyId,
                      email: email,
                      role: role,
                      invitedByUserId: user?.metadata.id ?? familyId,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAdultDialog(
      {required BuildContext context,
      required WidgetRef ref,
      required String familyId,
      required String profileId}) async {
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
                  decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Correo opcional')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdultProfileKind>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: AdultProfileKind.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(_adultKindLabel(value))))
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
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(adultProfileServiceProvider)
                    .createAdultProfile(CreateAdultProfileInput(
                      familyId: familyId,
                      profileId: profileId,
                      displayName: name,
                      kind: kind,
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                    ));
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
