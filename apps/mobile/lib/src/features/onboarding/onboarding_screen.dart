import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            const SizedBox(height: HabitarSpacing.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habitar', style: textTheme.displaySmall),
                    const SizedBox(height: HabitarSpacing.sm),
                    Text(
                      'Rutinas, habitos y acompanamiento familiar en un lugar calmo.',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: HabitarSpacing.lg),
                    const _WarmPanel(),
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Crear acompanamiento'),
                    ),
                    const SizedBox(height: HabitarSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Ya tengo cuenta'),
                    ),
                    const SizedBox(height: HabitarSpacing.lg),
                    Text(
                      'Puedes empezar en este dispositivo y luego conectar sincronizacion familiar cuando este lista.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmPanel extends StatelessWidget {
  const _WarmPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HabitarColors.sunlit,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(HabitarSpacing.lg),
      child: const Column(
        children: [
          _OnboardingRow(
            title: 'Mananas mas previsibles',
            body: 'Arma rutinas breves con pasos claros para cada perfil.',
            color: HabitarColors.calmGreen,
          ),
          SizedBox(height: HabitarSpacing.md),
          _OnboardingRow(
            title: 'Menos carga mental',
            body:
                'Guarda preferencias, recordatorios y acompanamiento semanal.',
            color: HabitarColors.softBlue,
          ),
          SizedBox(height: HabitarSpacing.md),
          _OnboardingRow(
            title: 'Apoyos a tiempo',
            body: 'Registra emociones, pausas y pequenas acciones de cuidado.',
            color: HabitarColors.supportRose,
          ),
        ],
      ),
    );
  }
}

class _OnboardingRow extends StatelessWidget {
  const _OnboardingRow({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: HabitarSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: HabitarSpacing.xs),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }
}
