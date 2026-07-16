import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'adulto@example.com');
  final _passwordController = TextEditingController(text: 'Cambiar123');
  var _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text('Volver a Habitar', style: textTheme.headlineSmall),
                    const SizedBox(height: HabitarSpacing.sm),
                    Text(
                      'Usa la cuenta del adulto para recuperar la sesion en este dispositivo.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: HabitarSpacing.lg),
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
                    if (_error != null) ...[
                      const SizedBox(height: HabitarSpacing.md),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Entrando...' : 'Entrar'),
                    ),
                    const SizedBox(height: HabitarSpacing.sm),
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => context.go('/register'),
                      child: const Text('Crear una cuenta nueva'),
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
      await ref.read(sessionServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(appRestoreProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'No pudimos entrar con esos datos. Revisa el email y la contrasena.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
