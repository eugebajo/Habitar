import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Perfil demo');
  final _ageController = TextEditingController(text: '9');
  ProfileKind _kind = ProfileKind.child;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear perfil')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(HabitarSpacing.lg),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Perfil infantil o adolescente',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: HabitarSpacing.md),
                    SegmentedButton<ProfileKind>(
                      segments: const [
                        ButtonSegment(
                            value: ProfileKind.child, label: Text('Infantil')),
                        ButtonSegment(
                            value: ProfileKind.teen,
                            label: Text('Adolescente')),
                      ],
                      selected: {_kind},
                      onSelectionChanged: (selection) =>
                          setState(() => _kind = selection.first),
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre visible'),
                      validator: _required,
                    ),
                    const SizedBox(height: HabitarSpacing.md),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Edad'),
                      keyboardType: TextInputType.number,
                      validator: _ageValidator,
                    ),
                    const SizedBox(height: HabitarSpacing.lg),
                    FilledButton(
                        onPressed: _submit, child: const Text('Crear perfil')),
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

  String? _ageValidator(String? value) {
    final age = int.tryParse(value ?? '');
    if (age == null || age < 3 || age > 17) {
      return 'Usa una edad entre 3 y 17';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) {
      context.go('/register');
      return;
    }
    final profile = await ref.read(profileServiceProvider).createProfile(
          CreateProfileInput(
            familyId: familyId,
            displayName: _nameController.text.trim(),
            age: int.parse(_ageController.text),
            kind: _kind,
          ),
        );
    ref.read(currentProfileIdProvider.notifier).state = profile.metadata.id;
    ref.read(currentProfileKindProvider.notifier).state = _kind;
    if (mounted) {
      context.go('/dashboard');
    }
  }
}
