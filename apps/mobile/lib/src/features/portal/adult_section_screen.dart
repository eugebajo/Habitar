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
