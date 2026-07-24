import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../dependencies.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  late Future<List<ProfileProgressSummary>> _summariesFuture;

  @override
  void initState() {
    super.initState();
    _summariesFuture = _loadSummaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<ProfileProgressSummary>>(
          future: _summariesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final summaries = snapshot.data ?? const [];
            if (summaries.isEmpty) {
              return HabitarPage(
                children: [
                  const SizedBox(height: HabitarSpacing.xl),
                  HabitarMoment(
                    title: '¿Quién usará Habitar?',
                    body:
                        'Creá el primer perfil para que el acompañamiento tenga nombre, ritmo y cuidado.',
                    color: HabitarColors.surfaceMist,
                    trailing: FilledButton(
                      onPressed: () => context.go('/profile'),
                      child: const Text('Agregar perfil'),
                    ),
                  ),
                ],
              );
            }

            return HabitarPage(
              maxWidth: 820,
              children: [
                const SizedBox(height: HabitarSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final text = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Quién usará Habitar?',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: HabitarSpacing.sm),
                        Text(
                          'Cada perfil abre un momento distinto: niño, adolescente o adulto.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: HabitarColors.mutedInk),
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return text;
                    }
                    return Row(
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: HabitarSpacing.xl),
                        const SizedBox(
                          width: 260,
                          child: HabitarSoftIllustration(height: 170),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: HabitarSpacing.xl),
                Wrap(
                  spacing: HabitarSpacing.md,
                  runSpacing: HabitarSpacing.md,
                  children: [
                    for (var index = 0; index < summaries.length; index += 1)
                      _ProfileTile(
                        summary: summaries[index],
                        color: _profileColor(index),
                        onOpen: () => _openProfile(summaries[index]),
                      ),
                    _AddProfileTile(onTap: () => context.go('/profile')),
                  ],
                ),
                const SizedBox(height: HabitarSpacing.xl),
                OutlinedButton(
                  onPressed: () => context.go('/adult-pin'),
                  child: const Text('Entrar como adulto'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<ProfileProgressSummary>> _loadSummaries() async {
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) {
      return const [];
    }
    return ref.read(profileServiceProvider).summariesForFamily(familyId);
  }

  void _openProfile(ProfileProgressSummary summary) {
    ref.read(currentProfileIdProvider.notifier).state = summary.profileId;
    ref.read(currentProfileKindProvider.notifier).state = summary.kind;
    context.go(summary.kind == ProfileKind.teen ? '/teen' : '/child');
  }

  Color _profileColor(int index) {
    const colors = [
      HabitarColors.calmGreen,
      HabitarColors.softBlue,
      HabitarColors.supportRose,
      HabitarColors.lavender,
      HabitarColors.warmGold,
    ];
    return colors[index % colors.length];
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.summary,
    required this.color,
    required this.onOpen,
  });

  final ProfileProgressSummary summary;
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final kindLabel =
        summary.kind == ProfileKind.child ? 'Niño/a' : 'Adolescente';
    final hasNext = summary.nextTaskTitle != null;

    return SizedBox(
      width: 240,
      child: InkWell(
        borderRadius: BorderRadius.circular(HabitarRadius.lg),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(HabitarRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitarAvatar(label: summary.displayName, color: color, size: 88),
              const SizedBox(height: HabitarSpacing.md),
              Text(summary.displayName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: HabitarSpacing.xs),
              Text('$kindLabel, ${summary.age} años'),
              const SizedBox(height: HabitarSpacing.md),
              LinearProgressIndicator(
                value: summary.progressFraction,
                minHeight: 8,
                borderRadius: BorderRadius.circular(HabitarRadius.pill),
              ),
              const SizedBox(height: HabitarSpacing.sm),
              Text(
                hasNext
                    ? 'Ahora: ${summary.nextTaskTitle}'
                    : 'Hoy no hay pasos asignados.',
              ),
              const SizedBox(height: HabitarSpacing.sm),
              Text(
                '${summary.completedGoals} metas cuidadas - ${summary.pendingTasks} pendientes',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: HabitarColors.mutedInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProfileTile extends StatelessWidget {
  const _AddProfileTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(HabitarRadius.lg),
        onTap: onTap,
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          decoration: BoxDecoration(
            color: HabitarColors.surfaceMist,
            borderRadius: BorderRadius.circular(HabitarRadius.lg),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  size: 44, color: HabitarColors.deepGreen),
              SizedBox(height: HabitarSpacing.md),
              Text('Agregar perfil', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
