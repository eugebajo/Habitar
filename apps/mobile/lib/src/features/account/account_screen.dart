import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _loading = false;

  Future<void> _showReauthAndRun(Future<void> Function(String password) action) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirmá con tu contraseña'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Confirmar')),
          ],
        );
      },
    );
    if (password == null || password.isEmpty) return;
    setState(() => _loading = true);
    try {
      await action(password);
    } on FamilyLifecycleException catch (error) {
      // OWNER_MUST_TRANSFER_OR_DELETE_FAMILY is handled at the call site
      // (see _confirmAndDeleteAccount), where it drives the two-exit
      // dialog instead of a plain error message - it should never reach
      // here. Every other code (FAMILY_DELETE_FORBIDDEN,
      // TRANSFER_FORBIDDEN, TRANSFER_TARGET_NOT_MEMBER) is a rejection the
      // user can just be told about.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_familyLifecycleErrorMessage(error.code))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _familyLifecycleErrorMessage(String code) {
    return switch (code) {
      'FAMILY_DELETE_FORBIDDEN' =>
        'Solo quien es dueño/a de la familia puede eliminarla.',
      'TRANSFER_FORBIDDEN' =>
        'Solo quien es dueño/a de la familia puede transferir su rol.',
      'TRANSFER_TARGET_NOT_MEMBER' =>
        'Esa persona ya no es parte de esta familia.',
      'OWNER_MUST_TRANSFER_OR_DELETE_FAMILY' =>
        'Antes de eliminar tu cuenta, transferí tu rol de dueño/a o eliminá toda la familia.',
      _ => 'No pudimos completar la acción. Intentá de nuevo.',
    };
  }

  Future<void> _confirmAndDeleteAccount({
    required String familyId,
    required List<FamilyMember> members,
    required String? myId,
    required bool amOwner,
  }) async {
    final hasOtherAdults = amOwner && members.length > 1;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar mi cuenta'),
            content: Text(
              hasOtherAdults
                  ? 'Vas a eliminar tu cuenta de forma permanente. Como sos dueño/a '
                      'de esta familia con otros adultos, antes vamos a pedirte que '
                      'transfieras tu rol o elimines toda la familia. ¿Confirmás?'
                  : 'Vas a eliminar tu cuenta de forma permanente. Esta acción no '
                      'se puede deshacer. ¿Confirmás?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, eliminar mi cuenta'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _showReauthAndRun((password) async {
      final authRepo = ref.read(authRepositoryProvider);
      final current = await authRepo.currentUser();
      if (current == null) return;
      await authRepo.signIn(email: current.email, password: password);
      try {
        await ref
            .read(familyRepositoryProvider)
            .deleteMyAccount(userId: current.metadata.id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Cuenta eliminada')));
        }
      } on FamilyLifecycleException catch (error) {
        if (error.code != 'OWNER_MUST_TRANSFER_OR_DELETE_FAMILY') rethrow;
        if (!mounted) return;
        await _offerOwnerExitOptions(
          familyId: familyId,
          members: members,
          myId: myId,
        );
      }
    });
  }

  /// Shown when deleteMyAccount rejects with
  /// OWNER_MUST_TRANSFER_OR_DELETE_FAMILY: the app has to force the choice
  /// the RPC refused to make on its own (see delete_my_account in
  /// supabase/migrations/0014_family_deletion.sql). Reuses the same
  /// transfer/delete-family flows the buttons below trigger directly, so
  /// there is exactly one implementation of each.
  Future<void> _offerOwnerExitOptions({
    required String familyId,
    required List<FamilyMember> members,
    required String? myId,
  }) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antes de eliminar tu cuenta'),
        content: const Text(
          'Sos dueño/a de esta familia y hay otros adultos en ella. Elegí una '
          'opción: transferir tu rol de dueño/a a otro adulto, o eliminar toda '
          'la familia (esto también le corta el acceso a los demás).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('transfer'),
            child: const Text('Transferir mi rol'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('delete_family'),
            child: const Text('Eliminar toda la familia'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'transfer') {
      await _confirmAndTransferOwnership(
          familyId: familyId, members: members, myId: myId);
    } else if (choice == 'delete_family') {
      await _confirmAndDeleteFamily(
          familyId: familyId, members: members, myId: myId);
    }
  }

  Future<void> _confirmAndDeleteFamily({
    required String familyId,
    required List<FamilyMember> members,
    required String? myId,
  }) async {
    final otherAdults = members
        .where((m) => m.userId != myId)
        .map((m) => (m.displayName ?? m.email ?? m.userId).toString())
        .join(', ');
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar todo el espacio familiar'),
            content: Text(
              'Vas a eliminar la familia y cortar el acceso de: $otherAdults. '
              'Esto borrará perfiles y rutinas. ¿Confirmás?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar familia'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _showReauthAndRun((password) async {
      final authRepo = ref.read(authRepositoryProvider);
      final current = await authRepo.currentUser();
      if (current == null) return;
      await authRepo.signIn(email: current.email, password: password);
      await ref.read(familyRepositoryProvider).deleteFamily(
            familyId: familyId,
            userId: current.metadata.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Familia eliminada')));
      }
    });
  }

  Future<void> _confirmAndTransferOwnership({
    required String familyId,
    required List<FamilyMember> members,
    required String? myId,
  }) async {
    final options = members.where((m) => m.userId != myId).toList();
    final selected = await showDialog<FamilyMember?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Transferir mi rol de dueño/a'),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(o),
              child: Text((o.displayName ?? o.email ?? o.userId).toString()),
            ),
        ],
      ),
    );
    if (selected == null) return;

    await _showReauthAndRun((password) async {
      final authRepo = ref.read(authRepositoryProvider);
      final current = await authRepo.currentUser();
      if (current == null) return;
      await authRepo.signIn(email: current.email, password: password);
      await ref.read(familyRepositoryProvider).transferFamilyOwnership(
            userId: current.metadata.id,
            newOwnerUserId: selected.userId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Propiedad transferida')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final familyRepo = ref.read(familyRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (familyId == null) const Text('No estás en ninguna familia.'),
              if (familyId != null)
                FutureBuilder(
                  future: Future.wait([
                    familyRepo.membersForFamily(familyId),
                    authRepo.currentUser(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final members = snapshot.data![0] as List<FamilyMember>;
                    final user = snapshot.data![1] as User?;
                    final myId = user?.metadata.id;
                    FamilyMember? myMembership;
                    for (final m in members) {
                      if (m.userId == myId) {
                        myMembership = m;
                        break;
                      }
                    }
                    final amOwner = myMembership != null && myMembership.role == FamilyMemberRole.owner;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text('Miembros de la familia:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final m in members)
                          ListTile(
                            title: Text((m.displayName ?? m.email ?? m.userId).toString()),
                            subtitle: Text(m.role.name),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _confirmAndDeleteAccount(
                                    familyId: familyId,
                                    members: members,
                                    myId: myId,
                                    amOwner: amOwner,
                                  ),
                          child: const Text('Eliminar mi cuenta'),
                        ),
                        const SizedBox(height: 8),
                        if (amOwner && members.length > 1)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: _loading
                                ? null
                                : () => _confirmAndDeleteFamily(
                                      familyId: familyId,
                                      members: members,
                                      myId: myId,
                                    ),
                            child: const Text('Eliminar todo el espacio familiar'),
                          ),
                        const SizedBox(height: 8),
                        if (amOwner && members.length > 1)
                          ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _confirmAndTransferOwnership(
                                      familyId: familyId,
                                      members: members,
                                      myId: myId,
                                    ),
                            child: const Text('Transferir mi rol de dueño/a'),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
