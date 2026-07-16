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
      appBar: AppBar(title: const Text('Registro del adulto')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: HabitarColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(HabitarSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crear acompanamiento familiar',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: HabitarSpacing.sm),
                          const Text(
                            'Primero registramos al adulto responsable y el espacio familiar.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre del adulto'),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration:
                          const InputDecoration(labelText: 'Contrasena'),
                      obscureText: true,
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _familyController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre de familia'),
                      validator: _required,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: HabitarSpacing.md),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Creando...' : 'Continuar'),
                    ),
                    const SizedBox(height: HabitarSpacing.sm),
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => context.go('/login'),
                      child: const Text('Ya tengo cuenta'),
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
              'No pudimos crear la cuenta. Revisa los datos o intenta entrar si ya existe.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
