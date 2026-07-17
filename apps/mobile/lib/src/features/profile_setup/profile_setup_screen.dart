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
      body: HabitarPage(
        maxWidth: 1080,
        children: [
          const SizedBox(height: HabitarSpacing.xl),
          HabitarCompanionLayout(
            eyebrow: 'Ahora pensemos en el',
            title: 'Quien usara Habitar?',
            body:
                'Cada persona necesita un modo distinto de sentirse acompanada. Empezamos con lo esencial.',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _KindCard(
                          selected: _kind == ProfileKind.child,
                          title: 'Nino o nina',
                          body: 'Pasos claros, poca carga y mucho sosten.',
                          onTap: () =>
                              setState(() => _kind = ProfileKind.child),
                        ),
                      ),
                      const SizedBox(width: HabitarSpacing.sm),
                      Expanded(
                        child: _KindCard(
                          selected: _kind == ProfileKind.teen,
                          title: 'Adolescente',
                          body: 'Mas autonomia, tono sobrio y respeto.',
                          onTap: () => setState(() => _kind = ProfileKind.teen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Como quiere que le llamemos?',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: HabitarSpacing.md),
                  TextFormField(
                    controller: _ageController,
                    decoration:
                        const InputDecoration(labelText: 'Cuantos anos tiene?'),
                    keyboardType: TextInputType.number,
                    validator: _ageValidator,
                  ),
                  const SizedBox(height: HabitarSpacing.lg),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Preparar su acompanamiento'),
                  ),
                ],
              ),
            ),
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
      context.go('/profiles');
    }
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(HabitarRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: HabitarMotion.gentle,
        padding: const EdgeInsets.all(HabitarSpacing.md),
        decoration: BoxDecoration(
          color: selected ? HabitarColors.sunlit : Colors.white,
          borderRadius: BorderRadius.circular(HabitarRadius.lg),
          border: Border.all(
            color: selected
                ? HabitarColors.deepGreen
                : HabitarColors.deepGreen.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.xs),
            Text(body),
          ],
        ),
      ),
    );
  }
}
