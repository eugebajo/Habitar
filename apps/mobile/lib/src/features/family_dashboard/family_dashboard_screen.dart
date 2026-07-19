import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

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
                  Text('Hola. Que necesita tu familia hoy?',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                      hasProfile
                          ? 'Perfil seleccionado - listo para acompanar'
                          : 'Elige un perfil para comenzar',
                      style: const TextStyle(color: HabitarColors.mutedInk)),
                ])),
            PopupMenuButton<String>(
                tooltip: 'Mas opciones',
                onSelected: (value) {
                  if (value == 'settings') context.go('/settings');
                  if (value == 'logout') _signOut(context, ref);
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'settings', child: Text('Configuracion')),
                      PopupMenuItem(
                          value: 'logout', child: Text('Cerrar sesion'))
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
          Text('Accesos rapidos',
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
                    label: 'Crear habito',
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
                                  : 'Sin prioridades todavia',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                              hasProfile
                                  ? 'Proximo: preparar la mochila - 18:30'
                                  : 'Crea o selecciona un perfil.',
                              style: const TextStyle(
                                  color: HabitarColors.mutedInk))
                        ]))
                  ]))),
          const SizedBox(height: 18),
          Text('Resumen semanal',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _SummaryRow(
              icon: Icons.check_circle_outline,
              title: 'Habitos completados',
              value: '8'),
          const _SummaryRow(
              icon: Icons.favorite_outline,
              title: 'Logro reciente',
              value: 'Pidio una pausa'),
          const _SummaryRow(
              icon: Icons.battery_2_bar_rounded,
              title: 'Momento mas dificil',
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
