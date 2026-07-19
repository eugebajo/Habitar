import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: HabitarPage(
          maxWidth: 1060,
          children: [
            Semantics(
              header: true,
              child: HabitarStage(
                eyebrow: 'HABITAR',
                title: 'Habitos posibles para familias reales.',
                body:
                    'Rutinas visuales, pequenos pasos y acompanamiento para cada etapa.',
                primaryLabel: 'Crear mi espacio',
                onPrimary: () => context.go('/register'),
                secondaryLabel: 'Ya tengo una cuenta',
                onSecondary: () => context.go('/login'),
                footer: const Row(children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: HabitarColors.primaryGreen),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Sin castigos, comparaciones ni presion por rachas.')),
                ]),
              ),
            ),
          ],
        ),
      );
}
