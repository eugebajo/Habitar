import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';
import '../../local_restore.dart';

class PendingInvitationScreen extends ConsumerStatefulWidget {
  const PendingInvitationScreen({super.key});

  @override
  ConsumerState<PendingInvitationScreen> createState() =>
      _PendingInvitationScreenState();
}

class _PendingInvitationScreenState
    extends ConsumerState<PendingInvitationScreen> {
  var _isAccepting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final restore = ref.watch(appRestoreProvider);
    final pending = restore.valueOrNull?.pendingInvitation;

    return Scaffold(
      body: HabitarPage(
        maxWidth: 620,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        children: [
          const Center(child: HabitarLogo(size: 70)),
          const SizedBox(height: 24),
          HabitarCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Te invitaron a una familia',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                if (pending == null)
                  const Text(
                    'No encontramos una invitacion pendiente para esta cuenta.',
                    textAlign: TextAlign.center,
                  )
                else ...[
                  _DetailRow(label: 'Familia', value: pending.familyName),
                  _DetailRow(
                    label: 'Rol',
                    value: _roleLabel(pending.invitation.role),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  HabitarConversationCard(
                    title: 'No pudimos unir esta cuenta',
                    body: _error!,
                    color: HabitarColors.surfaceWarm,
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed:
                      pending == null || _isAccepting ? null : _acceptInvite,
                  child: Text(_isAccepting
                      ? 'Uniendo...'
                      : 'Unirme a la familia'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed:
                      _isAccepting ? null : () => context.go('/onboarding'),
                  child: const Text('Ahora no'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvite() async {
    final pending = ref.read(appRestoreProvider).valueOrNull?.pendingInvitation;
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (pending == null || user == null) {
      setState(
          () => _error = 'Volvi a iniciar sesion para aceptar la invitacion.');
      return;
    }
    setState(() {
      _isAccepting = true;
      _error = null;
    });
    try {
      await ref.read(familyRepositoryProvider).acceptInvitation(
            invitationId: pending.invitation.metadata.id,
            userId: user.metadata.id,
            userEmail: user.email,
          );
      final family =
          await ref.read(familyRepositoryProvider).currentFamily(user.metadata.id);
      if (family == null) {
        throw StateError('Family membership was not loaded after accept.');
      }
      ref.read(currentFamilyIdProvider.notifier).state = family.metadata.id;
      final children = await ref
          .read(profileRepositoryProvider)
          .childProfiles(family.metadata.id);
      if (children.isNotEmpty) {
        ref.read(currentProfileIdProvider.notifier).state =
            children.first.metadata.id;
        ref.read(currentProfileKindProvider.notifier).state = ProfileKind.child;
      } else {
        final teens = await ref
            .read(profileRepositoryProvider)
            .teenProfiles(family.metadata.id);
        if (teens.isNotEmpty) {
          ref.read(currentProfileIdProvider.notifier).state =
              teens.first.metadata.id;
          ref.read(currentProfileKindProvider.notifier).state = ProfileKind.teen;
        }
      }
      ref.invalidate(appRestoreProvider);
      if (mounted) context.go('/profiles');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'La invitacion ya no esta disponible o no corresponde a este correo.';
      });
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(color: HabitarColors.mutedInk),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
}

String _roleLabel(FamilyMemberRole role) {
  return switch (role) {
    FamilyMemberRole.owner => 'Responsable',
    FamilyMemberRole.parent => 'Padre/Madre',
    FamilyMemberRole.caregiver => 'Cuidador',
    FamilyMemberRole.professional => 'Profesional',
    FamilyMemberRole.viewer => 'Visualizador',
  };
}
