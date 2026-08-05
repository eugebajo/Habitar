import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_design_system/design_system.dart';
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
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Hola. Ã‚Â¿QuÃƒÂ© necesita tu familia hoy?',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                      hasProfile
                          ? 'Perfil seleccionado - listo para acompaÃƒÂ±ar'
                          : 'ElegÃƒÂ­ un perfil para comenzar',
                      style: const TextStyle(color: HabitarColors.mutedInk)),
                ])),
            PopupMenuButton<String>(
                tooltip: 'MÃƒÂ¡s opciones',
                onSelected: (value) {
                  if (value == 'settings') context.go('/settings');
                  if (value == 'logout') _signOut(context, ref);
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'settings', child: Text('ConfiguraciÃƒÂ³n')),
                      PopupMenuItem(
                          value: 'logout', child: Text('Cerrar sesiÃƒÂ³n'))
                    ]),
          ]),
          const SizedBox(height: 18),
          InkWell(
              onTap: () => context.go('/profiles'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    HabitarAvatar(label: hasProfile ? 'Perfil' : '+', size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            hasProfile
                                ? 'Cambiar de perfil'
                                : 'Seleccionar perfil',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.expand_more_rounded)
                  ]))),
          const SizedBox(height: 26),
          Text('Accesos rÃƒÂ¡pidos',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 760 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _Quick(
                    icon: Icons.route_rounded,
                    label: 'Crear rutina',
                    color: HabitarColors.surfaceMist,
                    onTap: () => context
                        .go(hasProfile ? '/routine/create' : '/profiles')),
                _Quick(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Crear hÃƒÂ¡bito',
                    color: HabitarColors.sunlit,
                    onTap: () =>
                        context.go(hasProfile ? '/habits' : '/profiles')),
                _Quick(
                    icon: Icons.insights_rounded,
                    label: 'Ver progreso',
                    color: HabitarColors.softBlue.withValues(alpha: .22),
                    onTap: () => context.go('/progress')),
                _Quick(
                    icon: Icons.auto_stories_rounded,
                    label: 'Elegir cuento',
                    color: HabitarColors.lavender.withValues(alpha: .28),
                    onTap: () =>
                        context.go(hasProfile ? '/stories' : '/profiles')),
              ]),
          const SizedBox(height: 26),
          Text('Hoy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const ProgressRing(value: .67),
                    const SizedBox(width: 18),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              hasProfile
                                  ? '2 de 3 prioridades listas'
                                  : 'Sin prioridades todavÃƒÂ­a',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                              hasProfile
                                  ? 'PrÃƒÂ³ximo: preparar la mochila - 18:30'
                                  : 'Crea o selecciona un perfil.',
                              style: const TextStyle(
                                  color: HabitarColors.mutedInk))
                        ]))
                  ]))),
          if (hasProfile) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _sendRoutineSignal(context, ref),
              icon: const Icon(Icons.vibration_rounded),
              label: const Text('Enviar seÃ±al'),
            ),
          ],
          const SizedBox(height: 18),
          _AdultTeamCard(hasProfile: hasProfile),
          const SizedBox(height: 18),
          Text('Resumen semanal',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _SummaryRow(
              icon: Icons.check_circle_outline,
              title: 'HÃƒÂ¡bitos completados',
              value: '8'),
          const _SummaryRow(
              icon: Icons.favorite_outline,
              title: 'Logro reciente',
              value: 'PidiÃƒÂ³ una pausa'),
          const _SummaryRow(
              icon: Icons.battery_2_bar_rounded,
              title: 'Momento mÃƒÂ¡s difÃƒÂ­cil',
              value: 'Tardes'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () =>
                  context.go(ref.read(currentProfileKindProvider) == null
                      ? '/profiles'
                      : ref.read(currentProfileKindProvider)!.name == 'teen'
                          ? '/teen'
                          : '/child'),
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('Abrir espacio personal')),
        ]),
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
            content: Text('Primero preparÃ¡ una rutina para este perfil.')),
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
        content: Text(plan.isBlocked
            ? plan.blockedReason!
            : 'SeÃ±al enviada con suavidad.'),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionServiceProvider).signOut();
    ref.read(currentFamilyIdProvider.notifier).state = null;
    ref.read(currentProfileIdProvider.notifier).state = null;
    ref.invalidate(appRestoreProvider);
    if (context.mounted) context.go('/onboarding');
  }
}

class _Quick extends StatelessWidget {
  const _Quick(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 30, color: HabitarColors.deepGreen),
                    Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w800))
                  ]))));
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: Icon(icon, color: HabitarColors.primaryGreen),
          title: Text(title),
          trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700)))));
}

class _AdultTeamCard extends ConsumerWidget {
  const _AdultTeamCard({required this.hasProfile});

  final bool hasProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final profileId = ref.watch(currentProfileIdProvider);
    if (!hasProfile || familyId == null || profileId == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.groups_rounded,
              color: HabitarColors.primaryGreen),
          title: const Text('Equipo adulto'),
          subtitle:
              const Text('ElegÃƒÂ­ un perfil para sumar acompaÃƒÂ±antes.'),
          trailing: TextButton(
            onPressed: () => context.go('/profiles'),
            child: const Text('Perfiles'),
          ),
        ),
      );
    }
    return FutureBuilder<List<AdultProfile>>(
      future: ref
          .watch(adultProfileServiceProvider)
          .adultProfilesForProfile(profileId),
      builder: (context, snapshot) {
        final adults = snapshot.data ?? const <AdultProfile>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Icon(Icons.groups_rounded,
                      color: HabitarColors.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Equipo adulto',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddAdultDialog(
                      context: context,
                      ref: ref,
                      familyId: familyId,
                      profileId: profileId,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                  ),
                ]),
                const SizedBox(height: 8),
                if (adults.isEmpty)
                  const Text(
                    'SumÃƒÂ¡ madres, padres, cuidadores, docentes o profesionales vinculados a este perfil.',
                    style: TextStyle(color: HabitarColors.mutedInk),
                  )
                else
                  for (final adult in adults)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: HabitarAvatar(
                        label: adult.displayName,
                        size: 40,
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
            ),
          ),
        );
      },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Correo opcional'),
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
                    if (value != null) {
                      setDialogState(() => kind = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
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
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _adultKindLabel(AdultProfileKind kind) {
  return switch (kind) {
    AdultProfileKind.parent => 'Madre, padre o tutor',
    AdultProfileKind.caregiver => 'Cuidador',
    AdultProfileKind.professional => 'Profesional',
    AdultProfileKind.teacher => 'Docente',
  };
}
