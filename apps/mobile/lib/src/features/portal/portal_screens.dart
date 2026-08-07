import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../components/adult_shell.dart';

class AdultSectionScreen extends StatelessWidget {
  const AdultSectionScreen({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final data = switch (kind) {
      'routines' => (
          'Rutinas',
          Icons.route_rounded,
          'Organiza secuencias claras de 3 a 7 pasos.',
          '/routine/create',
          'Crear rutina'
        ),
      'progress' => (
          'Progreso semanal',
          Icons.insights_rounded,
          'Una mirada simple, sin comparaciones ni castigos.',
          '/rewards',
          'Ver logros'
        ),
      'habits' => (
          'Hábitos',
          Icons.wb_sunny_rounded,
          'Activá como máximo tres cambios pequeños a la vez.',
          '/habits',
          'Crear hábito'
        ),
      'rewards' => (
          'Recompensas',
          Icons.celebration_rounded,
          'Reconoce el esfuerzo con opciones elegidas en familia.',
          '/dashboard',
          'Volver al inicio'
        ),
      'settings' => (
          'Configuración',
          Icons.tune_rounded,
          'Ajusta accesibilidad, privacidad y experiencia sensorial.',
          '/privacy',
          'Privacidad'
        ),
      _ => (
          'HABITAR',
          Icons.favorite_rounded,
          'Un espacio familiar para avanzar paso a paso.',
          '/dashboard',
          'Ir al inicio'
        ),
    };
    return AdultPage(
      title: data.$1,
      action: FilledButton.icon(
          onPressed: () => context.go(data.$4),
          icon: const Icon(Icons.add_rounded),
          label: Text(data.$5)),
      child: GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 3 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: [
          _Stat(
              icon: data.$2,
              label: data.$3,
              value: kind == 'progress' ? '68%' : 'Todo listo'),
          const _Stat(
              icon: Icons.check_circle_outline,
              label: 'Completados esta semana',
              value: '8 pasos'),
          const _Stat(
              icon: Icons.favorite_outline,
              label: 'Logro reciente',
              value: 'Pidió ayuda'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                  backgroundColor: HabitarColors.surfaceMist,
                  child: Icon(icon, color: HabitarColors.deepGreen)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                    Text(label,
                        maxLines: 2,
                        style: const TextStyle(color: HabitarColors.mutedInk))
                  ])),
            ])),
      );
}

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
                    label: 'Tomi', size: 64, color: HabitarColors.softBlue),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Hola, Tomi',
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

class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen(
      {super.key,
      required this.title,
      required this.message,
      this.teen = false});
  final String title;
  final String message;
  final bool teen;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            EmptyState(
                icon: teen ? Icons.lock_person_outlined : Icons.star_rounded,
                title: title,
                message: message),
            const Spacer(),
            FilledButton(
                onPressed: () => context.pop(), child: const Text('Volver'))
          ])));
}

class AdultPinScreen extends StatelessWidget {
  const AdultPinScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Espacio adulto')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Verificar cuenta adulta',
                    message:
                        'Las rutinas, hábitos y cambios familiares quedan protegidos.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => showAdultPin(context),
                    child: const Text('Verificar acceso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

void showAdultPin(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verificar adulto'),
      content: const Text(
        'Para administrar rutinas, perfiles y recompensas, entrá con la cuenta adulta.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.go('/login');
          },
          child: const Text('Entrar como adulto'),
        ),
      ],
    ),
  );
}
