import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class AdultShell extends StatelessWidget {
  const AdultShell({super.key, required this.child});
  final Widget child;

  static const destinations = [
    ('Inicio', Icons.home_rounded, '/dashboard'),
    ('Rutinas', Icons.route_rounded, '/routines'),
    ('Progreso', Icons.insights_rounded, '/progress'),
    ('Biblioteca', Icons.auto_stories_rounded, '/stories'),
    ('Familia', Icons.family_restroom_rounded, '/profiles'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = destinations.indexWhere((item) =>
        location == item.$3 || (item.$3 != '/dashboard' && location.startsWith(item.$3)));
    final current = selected < 0 ? 0 : selected;
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      );
      if (desktop) {
        return Scaffold(
          body: Row(children: [
            NavigationRail(
              extended: constraints.maxWidth >= 1120,
              selectedIndex: current,
              onDestinationSelected: (i) => context.go(destinations[i].$3),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('HABITAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: HabitarColors.deepGreen)),
              ),
              destinations: [for (final item in destinations) NavigationRailDestination(icon: Icon(item.$2), label: Text(item.$1))],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ]),
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: (i) => context.go(destinations[i].$3),
          destinations: [for (final item in destinations) NavigationDestination(icon: Icon(item.$2), label: item.$1)],
        ),
      );
    });
  }
}

class AdultPage extends StatelessWidget {
  const AdultPage({super.key, required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AdultShell(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)), if (action != null) action!]),
            const SizedBox(height: 20),
            child,
          ]),
        ),
      );
}
