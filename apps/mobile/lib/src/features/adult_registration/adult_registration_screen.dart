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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _familyController = TextEditingController();
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
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          HabitarCompanionLayout(
            eyebrow: 'Primer paso',
            title: 'Contame quién sostiene este espacio.',
            body:
                'No necesitamos todo ahora. Solo lo suficiente para cuidar a tu familia con calma.',
            child: HabitarCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '¿Cómo te llamás?',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _familyController,
                      decoration: const InputDecoration(
                        labelText: '¿Cómo llamamos a tu familia?',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo para volver',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña tranquila',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                      validator: _required,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: HabitarSpacing.md),
                      HabitarConversationCard(
                        title: 'No pudimos crear el espacio todavía',
                        body: _error!,
                        color: HabitarColors.surfaceWarm,
                      ),
                    ],
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _isSubmitting
                                  ? 'Preparando tu espacio...'
                                  : 'Seguir con mi familia',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
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
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Completá este dato';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (mounted) context.go('/profile');
    } catch (error) {
      if (mounted) setState(() => _error = _registrationErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _registrationErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('already') ||
        message.contains('registered') ||
        message.contains('exists')) {
      return 'Ese correo parece estar registrado. Tocá "Ya tengo mi espacio" e intentá entrar con la misma contraseña.';
    }
    if (message.contains('password')) {
      return 'La contraseña no cumple los requisitos. Probá con una contraseña más larga, con letras y números.';
    }
    if (message.contains('confirm') || message.contains('email')) {
      return 'Ese correo necesita confirmación. Revisá tu email e intentá entrar nuevamente.';
    }
    return 'No pudimos crear el espacio todavía. Revisá los datos e intentá nuevamente.';
  }
}
