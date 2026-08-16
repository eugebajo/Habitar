import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

/// "Tengo un código de invitación": lets a second adult join a family by
/// pasting the code shared over WhatsApp. Works both for someone who just
/// registered (redirected here via `?next=/invitation/redeem`) and for
/// someone who already has an account and a family of their own.
class RedeemInvitationCodeScreen extends ConsumerStatefulWidget {
  const RedeemInvitationCodeScreen({super.key});

  @override
  ConsumerState<RedeemInvitationCodeScreen> createState() =>
      _RedeemInvitationCodeScreenState();
}

class _RedeemInvitationCodeScreenState
    extends ConsumerState<RedeemInvitationCodeScreen> {
  final _codeController = TextEditingController();
  var _isLoadingUser = true;
  User? _user;
  var _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoadingUser = false;
    });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tengo un código de invitación',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Pegá el código que te compartieron por WhatsApp para sumarte a esa familia.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                if (_isLoadingUser)
                  const Center(child: CircularProgressIndicator())
                else if (_user == null)
                  _buildSignedOutPrompt(context)
                else
                  _buildCodeForm(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOutPrompt(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Necesitás una cuenta para aceptar una invitación. Creá tu cuenta '
          'o iniciá sesión, y volvé a pegar el código.',
          textAlign: TextAlign.center,
          style: TextStyle(color: HabitarColors.mutedInk),
        ),
        const SizedBox(height: HabitarSpacing.lg),
        FilledButton(
          onPressed: () => context.go('/register?next=/invitation/redeem'),
          child: const Text('Crear cuenta'),
        ),
        const SizedBox(height: HabitarSpacing.sm),
        OutlinedButton(
          onPressed: () => context.go('/login?next=/invitation/redeem'),
          child: const Text('Ya tengo una cuenta'),
        ),
      ],
    );
  }

  Widget _buildCodeForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeController,
          enabled: !_isSubmitting,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: HabitarSpacing.md),
          HabitarConversationCard(
            title: 'No pudimos usar este código',
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
              Text(_isSubmitting ? 'Uniendo...' : 'Aceptar invitación'),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Pegá el código para continuar.');
      return;
    }
    final user = _user;
    if (user == null) return;

    final confirmed = await _confirmIfLeavingFamilyWithContent(user);
    if (!confirmed) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(familyRepositoryProvider).acceptInvitationByCode(
                code: code,
                userId: user.metadata.id,
                userEmail: user.email,
              );
      ref.read(currentFamilyIdProvider.notifier).state = result.familyId;
      final profileRepository = ref.read(profileRepositoryProvider);
      final children = await profileRepository.childProfiles(result.familyId);
      if (children.isNotEmpty) {
        ref.read(currentProfileIdProvider.notifier).state =
            children.first.metadata.id;
        ref.read(currentProfileKindProvider.notifier).state = ProfileKind.child;
      } else {
        final teens = await profileRepository.teenProfiles(result.familyId);
        if (teens.isNotEmpty) {
          ref.read(currentProfileIdProvider.notifier).state =
              teens.first.metadata.id;
          ref.read(currentProfileKindProvider.notifier).state =
              ProfileKind.teen;
        }
      }
      ref.invalidate(appRestoreProvider);
      if (mounted) context.go('/dashboard');
    } on FamilyInvitationException catch (_) {
      // Deliberately the same message for every case the backend collapses
      // into one (invalid, expired, used, canceled, wrong email) - see the
      // comment on accept_family_invitation_by_code in
      // supabase/migrations/0010_invitation_codes.sql for why.
      if (!mounted) return;
      setState(() {
        _error = 'Verificá que sea correcto y que hayas iniciado sesión con '
            'el correo al que te invitaron.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Intentá nuevamente en un momento.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// If [user] currently belongs to a family that already has profiles
  /// (children/teens - and therefore possibly routines), warns that
  /// accepting will leave that family and everything in it becomes
  /// unreachable, since redeeming a code is a one-family-per-adult, one-way
  /// move. Returns true to proceed. A brand-new, still-empty family (the
  /// one auto-created at registration) doesn't warrant scaring anyone, so
  /// this returns true immediately when there's nothing to lose.
  Future<bool> _confirmIfLeavingFamilyWithContent(User user) async {
    final familyRepository = ref.read(familyRepositoryProvider);
    final currentFamily =
        await familyRepository.currentFamily(user.metadata.id);
    if (currentFamily == null) {
      return true;
    }
    final profileRepository = ref.read(profileRepositoryProvider);
    final familyId = currentFamily.metadata.id;
    final children = await profileRepository.childProfiles(familyId);
    final teens = children.isEmpty
        ? await profileRepository.teenProfiles(familyId)
        : const [];
    if (children.isEmpty && teens.isEmpty) {
      return true;
    }
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Aceptar esta invitación?'),
        content: const Text(
          'Al aceptar, vas a dejar tu familia actual y sumarte a la del '
          'código que pegaste. Los perfiles y rutinas que hayas creado en '
          'tu familia anterior dejarán de estar disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aceptar invitación'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
