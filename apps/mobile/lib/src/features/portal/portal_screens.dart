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
            child: ListView(padding: const EdgeInsets.all(20), children: [
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
            IconButton(
                tooltip: 'Cómo me siento',
                onPressed: () => context.go('/child/emotions'),
                icon: const Icon(Icons.mood_rounded))
          ]),
          const SizedBox(height: 28),
          const Text('Ahora',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: HabitarColors.deepGreen)),
          const SizedBox(height: 8),
          _KidAction(
              color: HabitarColors.surfaceMist,
              icon: Icons.backpack_rounded,
              title: 'Prepararnos para salir',
              subtitle: '3 pasos - 8 min',
              action: 'Empezar',
              onTap: () => context.go('/routine/player')),
          const SizedBox(height: 16),
          const Text('Después: tiempo libre',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            ActionChip(
                avatar: const Icon(Icons.emoji_events_rounded),
                label: const Text('Mis logros'),
                onPressed: () => context.go('/child/achievements')),
            ActionChip(
                avatar: const Icon(Icons.auto_stories_rounded),
                label: const Text('Cuentos'),
                onPressed: () => context.go('/child/stories'))
          ]),
          const SizedBox(height: 32),
          OutlinedButton.icon(
              onPressed: () => showAdultPin(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Espacio adulto')),
        ])),
      );
}

class _KidAction extends StatelessWidget {
  const _KidAction(
      {required this.color,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.action,
      required this.onTap});
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Icon(icon, size: 48, color: HabitarColors.deepGreen),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(subtitle)
            ])),
        FilledButton(onPressed: onTap, child: Text(action))
      ]));
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
                    title: 'Confirma el PIN adulto',
                    message:
                        'Las rutinas, hábitos y cambios familiares quedan protegidos.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => showAdultPin(context),
                    child: const Text('Ingresar PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

void showAdultPin(BuildContext context) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ingresa el PIN adulto'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        decoration: const InputDecoration(labelText: 'PIN demo: 1234'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text != '1234') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN incorrecto')),
              );
              return;
            }
            Navigator.pop(dialogContext);
            context.go('/dashboard');
          },
          child: const Text('Entrar'),
        ),
      ],
    ),
  );
}
