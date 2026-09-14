import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class AdultShell extends StatelessWidget {
  const AdultShell({super.key, required this.child});
  final Widget child;

  // Bloque 2 de la etapa 1 del rediseño (docs/prototipo-habitar.md,
  // componente "NavBar"): exactamente 4 destinos - Inicio, Rutinas,
  // Progreso, Familia. Antes habia 5 (incluia 'Biblioteca' → '/stories').
  //
  // Ícono relleno (activo) + ícono outline (inactivo) por destino, según
  // la spec ("activo... ícono relleno, inactivo... ícono outline") - ver
  // AdultBottomNavItem más abajo, que elige entre los dos según selección.
  //
  // IMPORTANTE: sacar 'Biblioteca' deja '/stories' (story_library_screen.dart)
  // sin ninguna entrada de navegación para el adulto - antes solo se
  // llegaba ahí desde este shell, y ningún otro lugar de la app enlaza a
  // '/stories' para un adulto (grep verificado). La ruta sigue existiendo
  // en app.dart, pero queda huérfana hasta que una etapa futura decida
  // dónde reubicarla - no se toca ninguna pantalla individual en esta
  // etapa para agregarle un link de reemplazo.
  static const destinations = [
    (
      'Inicio',
      Icons.home_rounded,
      Icons.home_outlined,
      '/dashboard',
    ),
    (
      'Rutinas',
      Icons.checklist_rounded,
      Icons.checklist_outlined,
      '/routines',
    ),
    (
      'Progreso',
      Icons.bar_chart_rounded,
      Icons.bar_chart_outlined,
      '/progress',
    ),
    (
      'Familia',
      Icons.group_rounded,
      Icons.group_outlined,
      '/profiles',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = destinations.indexWhere((item) =>
        location == item.$4 ||
        (item.$4 != '/dashboard' && location.startsWith(item.$4)));
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
              onDestinationSelected: (i) => context.go(destinations[i].$4),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: HabitarWordmark(compact: true),
              ),
              destinations: [
                for (final item in destinations)
                  NavigationRailDestination(
                    icon: Icon(item.$3),
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
        bottomNavigationBar: AdultBottomNav(
          current: current,
          onSelected: (i) => context.go(destinations[i].$4),
        ),
      );
    });
  }
}

/// Barra de navegación inferior plana del bloque 2 - sin el indicador
/// (píldora) de Material 3 que usaba el `NavigationBar` de antes. Solo el
/// color y el ícono relleno/outline distinguen el tab activo, según
/// docs/prototipo-habitar.md: activo `#3B6D11` con ícono relleno, inactivo
/// `#5F5E5A` con ícono outline, etiquetas 10px con `letter-spacing: 0.04em`,
/// borde superior 1px en `#C0DD97`, fondo cream. Pública (no privada a este
/// archivo) porque es el tipo de pieza que otra pantalla podría querer
/// reusar fuera de [AdultShell] si alguna etapa futura necesita el mismo
/// look sin el layout de shell completo.
class AdultBottomNav extends StatelessWidget {
  const AdultBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HabitarColors.cream,
        border: Border(
          top: BorderSide(color: HabitarColors.greenMedium, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        // Sin alto fijo para toda la barra: a textScale alto (accesibilidad -
        // adult_responsive_layout_test.dart ya cubre hasta 1.3x) la etiqueta
        // de cada item crece, y un SizedBox(height: 64) fijo desbordaba
        // justo eso (hallazgo real al correr los tests despues de este
        // cambio, no algo que se dedujo a mano). Dejando que el Row mida su
        // propio alto segun el item mas alto, crece con el texto en vez de
        // desbordar.
        child: Row(
          children: [
            for (var i = 0; i < AdultShell.destinations.length; i++)
              Expanded(
                child: _AdultBottomNavItem(
                  label: AdultShell.destinations[i].$1,
                  filledIcon: AdultShell.destinations[i].$2,
                  outlineIcon: AdultShell.destinations[i].$3,
                  selected: i == current,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdultBottomNavItem extends StatelessWidget {
  const _AdultBottomNavItem({
    required this.label,
    required this.filledIcon,
    required this.outlineIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData filledIcon;
  final IconData outlineIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? HabitarColors.green : HabitarColors.gray;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // El padding vertical, no un alto fijo, es lo que le da al item
          // su tamaño de toque minimo - a textScale 1.0 esto ya supera los
          // 44px de HabitarButtonSize.adultMinHeight; a textScale alto
          // crece mas, nunca desborda.
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? filledIcon : outlineIcon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HabitarTypography.body,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  // 0.04em de 10px.
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 132),
            children: [
              HabitarScreenHeader(
                  title: title, subtitle: subtitle, trailing: action),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      );
}
