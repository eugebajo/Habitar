import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import 'adult_pin_screen.dart';

class TeenHomeScreen extends StatelessWidget {
  const TeenHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F6F7),
        appBar: AppBar(title: const Text('Mi espacio'), actions: [
          IconButton(
              tooltip: 'Privacidad',
              onPressed: () => context.go('/teen/privacy'),
              icon: const Icon(Icons.shield_outlined))
        ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Buenas tardes, Alex',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Tu día, a tu ritmo.',
              style: TextStyle(color: HabitarColors.mutedInk)),
          const SizedBox(height: 24),
          const _TeenTile(
              icon: Icons.flag_outlined,
              title: 'Objetivo de hoy',
              value: 'Preparar la mochila'),
          const _TeenTile(
              icon: Icons.task_alt_rounded,
              title: 'Hábitos activos',
              value: '2 de 3 completados'),
          const _TeenTile(
              icon: Icons.insights_rounded,
              title: 'Mi progreso',
              value: '4 días esta semana'),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: () => context.go('/teen/reflection'),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Reflexión diaria')),
          TextButton(
              onPressed: () => showAdultPin(context),
              child: const Text('Entrar al espacio adulto')),
        ]),
      );
}

class _TeenTile extends StatelessWidget {
  const _TeenTile(
      {required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          minTileHeight: 76,
          leading: Icon(icon, color: HabitarColors.deepGreen),
          title: Text(title),
          subtitle: Text(value),
          trailing: const Icon(Icons.chevron_right)));
}
