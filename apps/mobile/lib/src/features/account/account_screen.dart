import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \\$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    final members = snapshot.data![0] as List;
                    final user = snapshot.data![1];
                    final myId = (user as dynamic).metadata?.id ?? (user as dynamic).metadataId ?? null;
                    final myMembership = members.cast<dynamic>().firstWhere((m) => m.userId == myId, orElse: () => null);
                    final amOwner = myMembership != null && myMembership.role == 'owner' || (myMembership?.role is Enum && myMembership.role.name == 'owner');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text('Miembros de la familia:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final m in members)
                          ListTile(
                            title: Text((m.displayName ?? m.email ?? m.userId).toString()),
                            subtitle: Text((m.role is Enum) ? (m.role.name) : m.role.toString()),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : () async {
                            // Delete my account flow
                            await _showReauthAndRun((password) async {
                              final current = await authRepo.currentUser();
                              final email = (current as dynamic).email as String?;
                              if (email != null) {
                                await authRepo.signIn(email: email, password: password);
                              }
                              await familyRepo.deleteMyAccount(userId: (current as dynamic).metadata.id);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada')));
                            });
                          },
                          child: const Text('Eliminar mi cuenta'),
                        ),
                        const SizedBox(height: 8),
                        if (amOwner && members.length > 1)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: _loading ? null : () async {
                              // Delete family flow
                              final otherAdults = members.where((m) => m.userId != myId).map((m) => (m.displayName ?? m.email ?? m.userId).toString()).join(', ');
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar todo el espacio familiar'),
                                  content: Text('Vas a eliminar la familia y cortar el acceso de: $otherAdults. Esto borrará perfiles y rutinas. ¿Confirmás?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                    FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar familia')),
                                  ],
                                ),
                              ) ?? false;
                              if (!confirmed) return;
                              await _showReauthAndRun((password) async {
                                final current = await authRepo.currentUser();
                                final email = (current as dynamic).email as String?;
                                if (email != null) {
                                  await authRepo.signIn(email: email, password: password);
                                }
                                await familyRepo.deleteFamily(familyId: familyId, userId: (current as dynamic).metadata.id);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Familia eliminada')));
                              });
                            },
                            child: const Text('Eliminar todo el espacio familiar'),
                          ),
                        const SizedBox(height: 8),
                        if (amOwner && members.length > 1)
                          ElevatedButton(
                            onPressed: _loading ? null : () async {
                              // Transfer owner
                              final options = members.where((m) => m.userId != myId).toList();
                              final selected = await showDialog<dynamic>(
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
                                final current = await authRepo.currentUser();
                                final email = (current as dynamic).email as String?;
                                if (email != null) {
                                  await authRepo.signIn(email: email, password: password);
                                }
                                await familyRepo.transferFamilyOwnership(userId: (current as dynamic).metadata.id, newOwnerUserId: selected.userId);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propiedad transferida')));
                              });
                            },
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
