import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  var _isSubmitting = false;
  var _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
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
            onPressed: () => _returnToLogin(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Center(child: HabitarLogo(size: 64)),
          const SizedBox(height: 18),
          HabitarCard(
            color: HabitarColors.card,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recuperar contrasena',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Escribi el correo de tu cuenta y te enviaremos un enlace para crear una nueva contrasena.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HabitarSpacing.lg),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: HabitarSpacing.md),
                    HabitarConversationCard(
                      title: 'No pudimos enviar el enlace',
                      body: _error!,
                      color: HabitarColors.surfaceWarm,
                    ),
                  ],
                  if (_sent) ...[
                    const SizedBox(height: HabitarSpacing.md),
                    const HabitarConversationCard(
                      title: 'Revisa tu correo',
                      body:
                          'Te enviamos un enlace para crear una nueva contrasena.',
                      color: HabitarColors.surfaceMist,
                    ),
                  ],
                  const SizedBox(height: HabitarSpacing.lg),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting ? 'Enviando enlace...' : 'Enviar enlace',
                    ),
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => _returnToLogin(context),
                    child: const Text('Volver al inicio de sesion'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Completa tu correo';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
      _sent = false;
    });
    try {
      await ref.read(passwordRecoveryServiceProvider).requestReset(
            email: _emailController.text.trim(),
            redirectTo: passwordRecoveryRedirectUri(),
          );
      if (mounted) {
        setState(() => _sent = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'No pudimos completar la solicitud. Revisa el correo e intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _isSubmitting = false;
  var _updated = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
            onPressed: () => _returnToLogin(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Center(child: HabitarLogo(size: 64)),
          const SizedBox(height: 18),
          HabitarCard(
            color: HabitarColors.card,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crear nueva contrasena',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ingresa una nueva contrasena para volver a tu espacio.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HabitarSpacing.lg),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contrasena',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: true,
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contrasena',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    obscureText: true,
                    validator: _confirmValidator,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: HabitarSpacing.md),
                    HabitarConversationCard(
                      title: 'No pudimos guardar el cambio',
                      body: _error!,
                      color: HabitarColors.surfaceWarm,
                    ),
                  ],
                  if (_updated) ...[
                    const SizedBox(height: HabitarSpacing.md),
                    const HabitarConversationCard(
                      title: 'Contrasena actualizada',
                      body: 'Ya podes iniciar sesion con tu nueva contrasena.',
                      color: HabitarColors.surfaceMist,
                    ),
                  ],
                  const SizedBox(height: HabitarSpacing.lg),
                  FilledButton(
                    onPressed: _isSubmitting || _updated ? null : _submit,
                    child: Text(
                      _isSubmitting ? 'Guardando...' : 'Guardar contrasena',
                    ),
                  ),
                  const SizedBox(height: HabitarSpacing.sm),
                  TextButton(
                    onPressed: () => _returnToLogin(context),
                    child: const Text('Volver al inicio de sesion'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Usa al menos 8 caracteres';
    }
    return null;
  }

  String? _confirmValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(passwordRecoveryServiceProvider).updatePassword(
            password: _passwordController.text,
          );
      ref.read(passwordRecoveryActiveProvider.notifier).state = false;
      ref.invalidate(appRestoreProvider);
      if (mounted) {
        setState(() => _updated = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'No pudimos guardar la nueva contrasena. Abri nuevamente el enlace de recuperacion o solicita otro.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

@visibleForTesting
Uri passwordRecoveryRedirectUri({
  Uri? baseUri,
  bool? isWebOverride,
}) {
  final isRunningOnWeb = isWebOverride ?? kIsWeb;
  if (!isRunningOnWeb) {
    return Uri.parse('com.habitarpy.app://reset-password');
  }

  final base = baseUri ?? Uri.base;
  if (base.hasScheme && base.host.isNotEmpty) {
    if (base.host == 'habitarpy.com' || base.host == 'www.habitarpy.com') {
      return Uri.parse('https://habitarpy.com/app/#/reset-password');
    }
    return base.replace(
      path: base.path.startsWith('/app') ? '/app/' : '/',
      queryParameters: const <String, String>{},
      fragment: '/reset-password',
    );
  }
  return Uri.parse('https://habitarpy.com/app/#/reset-password');
}

void _returnToLogin(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/login');
}
