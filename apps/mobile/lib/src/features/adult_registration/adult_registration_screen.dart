import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
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
            title: 'Contame quien sostiene este espacio.',
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
                        labelText: 'Como te llamas?',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _familyController,
                      decoration: const InputDecoration(
                        labelText: 'Como llamamos a tu familia?',
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
                        labelText: 'Contrasena tranquila',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                      validator: _required,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: HabitarSpacing.md),
                      HabitarConversationCard(
                        title: _errorTitle(_error!),
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
    if (value == null || value.trim().isEmpty) return 'Completa este dato';
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
    } on EmailConfirmationRequiredException catch (error) {
      await _savePendingBootstrap(error.email);
      if (mounted) setState(() => _error = _registrationErrorMessage(error));
    } catch (error) {
      if (mounted) setState(() => _error = _registrationErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _registrationErrorMessage(Object error) {
    if (error is EmailConfirmationRequiredException) {
      return 'Te enviamos un enlace a ${error.email} para confirmar tu cuenta. Despues de confirmarla, volve a Habitar e inicia sesion para continuar.';
    }
    final message = error.toString().toLowerCase();
    if (message.contains('already') ||
        message.contains('registered') ||
        message.contains('exists')) {
      return 'Ese correo parece estar registrado. Toca "Ya tengo mi espacio" e intenta entrar con la misma contrasena.';
    }
    if (message.contains('password')) {
      return 'La contrasena no cumple los requisitos. Proba con una contrasena mas larga, con letras y numeros.';
    }
    if (message.contains('confirm') || message.contains('email')) {
      return 'Ese correo necesita confirmacion. Revisa tu email e intenta entrar nuevamente.';
    }
    return 'Revisa los datos e intenta nuevamente.';
  }

  String _errorTitle(String message) {
    if (message.startsWith('Te enviamos un enlace')) {
      return 'Revisa tu correo';
    }
    return 'No pudimos crear el espacio todavia';
  }

  Future<void> _savePendingBootstrap(String email) async {
    final store = ref.read(localStoreProvider);
    if (store == null) return;
    final normalizedEmail = email.trim().toLowerCase();
    await store.put(
      LocalStoreCollections.pendingFamilyBootstrap,
      normalizedEmail,
      {
        'email': normalizedEmail,
        'display_name': _nameController.text.trim(),
        'family_name': _familyController.text.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'completed': false,
      },
    );
  }
}
