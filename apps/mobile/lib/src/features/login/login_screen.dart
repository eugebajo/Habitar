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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    return Scaffold(
      body: HabitarPage(
        maxWidth: 620,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Center(child: HabitarLogo(size: 70)),
          const SizedBox(height: 18),
          HabitarCard(
            color: HabitarColors.card,
            child: Column(
              children: [
                const HabitarSoftIllustration(height: 170, label: 'home'),
                const SizedBox(height: 18),
                Text('Volvamos a\ntu espacio.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 10),
                Text(
                  'Usá el acceso del adulto. Habitar buscará lo preparado para tu familia.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo del adulto',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                ),
                const SizedBox(height: HabitarSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    suffixIcon: Icon(Icons.visibility_outlined),
                  ),
                  obscureText: true,
                  validator: _required,
                ),
                if (_error != null) ...[
                  const SizedBox(height: HabitarSpacing.md),
                  HabitarConversationCard(
                    title: 'No pudimos abrir el espacio todavía',
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
                      Text(_isSubmitting ? 'Buscando tu espacio...' : 'Entrar'),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _isSubmitting ? null : () => context.go('/recover'),
                        child: const Text('Olvidé mi contraseña'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => context.go('/register'),
                        child: const Text('Crear mi espacio familiar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const HabitarPill(
                  icon: Icons.lock_outline_rounded,
                  label:
                      'Tu información familiar no se muestra al niño desde esta entrada.',
                  color: HabitarColors.surfaceMist,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: HabitarSpacing.lg,
            children: [
              TextButton(
                  onPressed: () => context.go('/privacy'),
                  child: const Text('Privacidad')),
              TextButton(
                  onPressed: () => context.go('/terms'),
                  child: const Text('Términos')),
            ],
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
      await ref.read(sessionServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(appRestoreProvider);
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _loginErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _loginErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('not found') || message.contains('family')) {
      return 'Iniciamos sesión, pero tuvimos un problema al cargar tu espacio familiar. Intentá nuevamente.';
    }
    return 'No pudimos iniciar sesión. Revisá tu correo y contraseña.';
  }
}
