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
      body: HabitarPage(
        maxWidth: 560,
        children: [
          const SizedBox(height: HabitarSpacing.xl),
          HabitarMoment(
            title: 'Volvamos a tu espacio.',
            body:
                'Usa el acceso del adulto. Habitar buscara lo preparado para tu familia.',
            color: HabitarColors.surfaceMist,
          ),
          const SizedBox(height: HabitarSpacing.lg),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration:
                      const InputDecoration(labelText: 'Correo del adulto'),
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                ),
                const SizedBox(height: HabitarSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contrasena'),
                  obscureText: true,
                  validator: _required,
                ),
                if (_error != null) ...[
                  const SizedBox(height: HabitarSpacing.md),
                  HabitarConversationCard(
                    title: 'No pudimos abrir el espacio todavia',
                    body:
                        'Revisa el correo y la contrasena. Si es la primera vez, podemos crear tu espacio en un minuto.',
                    color: HabitarColors.surfaceWarm,
                  ),
                ],
                const SizedBox(height: HabitarSpacing.lg),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      Text(_isSubmitting ? 'Buscando tu espacio...' : 'Entrar'),
                ),
                const SizedBox(height: HabitarSpacing.sm),
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => context.go('/recover'),
                  child: const Text('Olvidé mi contraseña'),
                ),
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => context.go('/register'),
                  child: const Text('Crear mi espacio familiar'),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: HabitarSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/privacy'),
                      child: const Text('Privacidad'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/terms'),
                      child: const Text('Terminos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: HabitarSpacing.lg),
          Text(
            'Tu informacion familiar no se muestra al nino desde esta entrada.',
            style:
                textTheme.bodyMedium?.copyWith(color: HabitarColors.mutedInk),
            textAlign: TextAlign.center,
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
            'No pudimos entrar con esos datos. Revisa el correo y la contrasena.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
