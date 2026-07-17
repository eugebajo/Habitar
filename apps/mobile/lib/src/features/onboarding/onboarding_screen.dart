import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final moments = [
      _OnboardingMoment(
        title: 'Bienvenida a Habitar.',
        body:
            'Un lugar para acompanar a tu familia con calma, claridad y pequenos pasos posibles.',
        action: 'Comenzar',
      ),
      _OnboardingMoment(
        title: 'No estas llegando tarde.',
        body:
            'Hay dias intensos. Habitar ayuda a preparar lo importante sin juzgar lo que no salio.',
        action: 'Respirar y seguir',
      ),
      _OnboardingMoment(
        title: 'Primero cuidamos el vinculo.',
        body:
            'Rutinas, habitos, emociones y escuela se organizan alrededor de una pregunta simple: que necesita hoy?',
        action: 'Crear mi espacio',
      ),
    ];
    final moment = moments[_step];

    return Scaffold(
      body: HabitarPage(
        maxWidth: 1060,
        children: [
          AnimatedSwitcher(
            duration: HabitarMotion.gentle,
            child: HabitarStage(
              key: ValueKey(_step),
              eyebrow: 'Habitar',
              title: moment.title,
              body: moment.body,
              primaryLabel: moment.action,
              onPrimary: _next,
              secondaryLabel: 'Ya tengo mi espacio',
              onSecondary: () => context.go('/login'),
              footer: _StepDots(current: _step, total: moments.length),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    context.go('/register');
  }
}

class _OnboardingMoment {
  const _OnboardingMoment({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < total; index += 1)
          AnimatedContainer(
            duration: HabitarMotion.gentle,
            width: index == current ? 30 : 8,
            height: 8,
            margin: const EdgeInsets.only(right: HabitarSpacing.xs),
            decoration: BoxDecoration(
              color: index == current
                  ? HabitarColors.deepGreen
                  : HabitarColors.deepGreen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(HabitarRadius.pill),
            ),
          ),
      ],
    );
  }
}
