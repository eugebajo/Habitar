import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';

class AdultRegistrationScreen extends ConsumerStatefulWidget {
  const AdultRegistrationScreen({super.key});

  @override
  ConsumerState<AdultRegistrationScreen> createState() =>
      _AdultRegistrationScreenState();
}

class _AdultRegistrationScreenState
    extends ConsumerState<AdultRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Adulto cuidador');
  final _emailController = TextEditingController(text: 'adulto@example.com');
  final _passwordController = TextEditingController(text: 'Cambiar123');
  final _familyController = TextEditingController(text: 'Mi familia');
  var _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HabitarPage(
        maxWidth: 1080,
        children: [
          const SizedBox(height: HabitarSpacing.xl),
          HabitarCompanionLayout(
            eyebrow: 'Primer paso',
            title: 'Contame quién sostiene este espacio.',
            body:
                'No necesitamos todo ahora. Solo lo suficiente para cuidar a tu familia con calma.',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '¿Cómo te llamás?',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _familyController,
                    decoration: const InputDecoration(
                      labelText: '¿Cómo llamamos a tu familia?',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Correo para volver'),
                    keyboardType: TextInputType.emailAddress,
                    validator: _required,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña tranquila'),
                    obscureText: true,
                    validator: _required,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: HabitarSpacing.md),
                    const HabitarConversationCard(
                      title: 'No pudimos crear el espacio todavía',
                      body:
                          'Puede que ese correo ya exista. Intentá entrar o revisá los datos con calma.',
                      color: HabitarColors.surfaceWarm,
                    ),
                  ],
                  const SizedBox(height: HabitarSpacing.lg),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting
                        ? 'Preparando tu espacio...'
                        : 'Seguir con mi familia'),
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => context.go('/login'),
                    child: const Text('Ya tengo mi espacio'),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(adultRegistrationServiceProvider).register(
            AdultRegistrationInput(
              displayName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              familyName: _familyController.text.trim(),
            ),
          );
      ref.read(currentFamilyIdProvider.notifier).state =
          result.family.metadata.id;
      if (mounted) {
        context.go('/profile');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'No pudimos crear el espacio. Revisá los datos o intentá entrar si ya existe.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
