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
                    Text('Crear acompanamiento familiar',
                        style: Theme.of(context).textTheme.headlineSmall),
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
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Creando...' : 'Continuar'),
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
    setState(() => _isSubmitting = true);
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
  }
}
