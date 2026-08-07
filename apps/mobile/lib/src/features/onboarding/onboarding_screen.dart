import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: HabitarPage(
          maxWidth: 720,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          children: [
            const SizedBox(height: 10),
            const HabitarLogo(size: 70),
            const SizedBox(height: 18),
            const HabitarSoftIllustration(height: 310, label: 'home'),
            const SizedBox(height: 18),
            Text(
              'Hábitos posibles para familias reales.',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Rutinas visuales, pequeños pasos y acompañamiento para que cada día en casa sea más fácil.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            const Center(
              child: HabitarPill(
                icon: Icons.favorite_border_rounded,
                label: 'Sin castigos, comparaciones ni presión por rachas.',
                color: HabitarColors.surfaceMist,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Crear mi espacio'),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ya tengo una cuenta'),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: HabitarSpacing.lg,
              children: [
                TextButton(
                  onPressed: () => context.go('/privacy'),
                  child: const Text('Privacidad'),
                ),
                TextButton(
                  onPressed: () => context.go('/terms'),
                  child: const Text('Términos'),
                ),
              ],
            ),
          ],
        ),
      );
}
