import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class AdultShell extends StatelessWidget {
  const AdultShell({super.key, required this.child});
  final Widget child;

  static const destinations = [
    ('Inicio', Icons.home_rounded, '/dashboard'),
    ('Rutinas', Icons.checklist_rounded, '/routines'),
    ('Progreso', Icons.bar_chart_rounded, '/progress'),
    ('Biblioteca', Icons.auto_stories_rounded, '/stories'),
    ('Familia', Icons.group_rounded, '/profiles'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = destinations.indexWhere((item) =>
        location == item.$3 ||
        (item.$3 != '/dashboard' && location.startsWith(item.$3)));
    final current = selected < 0 ? 0 : selected;
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final content = DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HabitarColors.surface, Color(0xFFFFF8ED)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        ),
      );
      if (desktop) {
        return Scaffold(
          body: Row(children: [
            NavigationRail(
              backgroundColor: HabitarColors.card,
              extended: constraints.maxWidth >= 1120,
              selectedIndex: current,
              onDestinationSelected: (i) => context.go(destinations[i].$3),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: HabitarWordmark(compact: true),
              ),
              destinations: [
                for (final item in destinations)
                  NavigationRailDestination(
                    icon: Icon(item.$2),
                    selectedIcon: Icon(item.$2, color: HabitarColors.deepGreen),
                    label: Text(item.$1),
                  )
              ],
            ),
            const VerticalDivider(width: 1, color: HabitarColors.line),
            Expanded(child: content),
          ]),
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: current,
              onDestinationSelected: (i) => context.go(destinations[i].$3),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$2), label: item.$1)
              ],
            ),
          ),
        ),
      );
    });
  }
}

class AdultPage extends StatelessWidget {
  const AdultPage(
      {super.key,
      required this.title,
      required this.child,
      this.action,
      this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AdultShell(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(22), children: [
            HabitarScreenHeader(
                title: title, subtitle: subtitle, trailing: action),
            const SizedBox(height: 22),
            child,
          ]),
        ),
      );
}
