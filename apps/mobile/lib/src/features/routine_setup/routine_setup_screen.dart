import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';

class RoutineSetupScreen extends ConsumerStatefulWidget {
  const RoutineSetupScreen({super.key});

  @override
  ConsumerState<RoutineSetupScreen> createState() => _RoutineSetupScreenState();
}

class _RoutineSetupScreenState extends ConsumerState<RoutineSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Prepararse para salir');
  final _stepControllers = [
    TextEditingController(text: 'Guardar la botella'),
    TextEditingController(text: 'Ponerse los zapatos'),
    TextEditingController(text: 'Tomar la mochila'),
  ];
  var _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear rutina')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Rutina de 3 pasos',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre de la rutina'),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    for (var index = 0;
                        index < _stepControllers.length;
                        index += 1) ...[
                      TextFormField(
                        controller: _stepControllers[index],
                        decoration:
                            InputDecoration(labelText: 'Paso ${index + 1}'),
                        validator: _required,
                      ),
                      const SizedBox(height: HabitarSpacing.md),
                    ],
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                          _isSubmitting ? 'Preparando...' : 'Crear e iniciar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Completa este dato';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      context.go('/profile');
      return;
    }
    setState(() => _isSubmitting = true);
    final session = await ref.read(routineServiceProvider).createAndStart(
          CreateRoutineInput(
            profileId: profileId,
            title: _titleController.text.trim(),
            stepTitles: _stepControllers
                .map((controller) => controller.text.trim())
                .toList(growable: false),
          ),
        );
    ref.read(currentRoutineSessionIdProvider.notifier).state = session.id;
    if (mounted) {
      context.go('/routine/player');
    }
  }
}
