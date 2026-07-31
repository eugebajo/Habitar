import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import 'adult_pin_screen.dart';

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFFF8EA),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                const HabitarAvatar(
                    label: 'Nico', size: 64, color: HabitarColors.softBlue),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Hola, Nico',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Text('Viernes por la tarde',
                          style: TextStyle(color: HabitarColors.mutedInk))
                    ])),
              ]),
              const SizedBox(height: 24),
              _ChildPriorityCard(
                  color: HabitarColors.surfaceMist,
                  icon: Icons.backpack_rounded,
                  label: 'Ahora',
                  title: 'Prepararnos para salir',
                  body: 'Tres pasos claros, uno a la vez.',
                  action: 'Empezar',
                  onTap: () => context.go('/routine/player')),
              const SizedBox(height: 12),
              _ChildPriorityCard(
                  color: Colors.white,
                  icon: Icons.event_available_rounded,
                  label: 'Después',
                  title: 'Tiempo libre',
                  body: 'Cuando terminemos, descansamos.',
                  action: 'Ver',
                  onTap: () => context.go('/child/achievements')),
              const SizedBox(height: 12),
              _ChildPriorityCard(
                  color: HabitarColors.sunlit,
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Pedir ayuda',
                  title: 'No tengo que hacerlo solo',
                  body: 'Puedo pedir una pista o una pausa.',
                  action: 'Ayuda',
                  onTap: () => context.go('/child/emotions')),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                  onPressed: () => showAdultPin(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Espacio adulto')),
            ],
          ),
        ),
      );
}

class _ChildPriorityCard extends StatelessWidget {
  const _ChildPriorityCard(
      {required this.color,
      required this.icon,
      required this.label,
      required this.title,
      required this.body,
      required this.action,
      required this.onTap});
  final Color color;
  final IconData icon;
  final String label;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 34, color: HabitarColors.deepGreen),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: const TextStyle(
                            color: HabitarColors.deepGreen,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(body),
                  ])),
            ]),
            const SizedBox(height: 16),
            FilledButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );
}
