import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';

import '../../components/adult_shell.dart';
import '../../dependencies.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  var _refresh = 0;

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(currentProfileIdProvider);
    return AdultPage(
      title: 'Acuerdos y beneficios',
      action: FilledButton.icon(
        onPressed: profileId == null ? null : () => _grant(profileId, 5),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Acreditar 5 min'),
      ),
      child: profileId == null
          ? const EmptyState(
              icon: Icons.card_giftcard_rounded,
              title: 'ElegÃ­ un perfil',
              message:
                  'El banco de tiempo se calcula para cada niÃ±o o adolescente.',
            )
          : FutureBuilder<TimeBankSummary>(
              key: ValueKey(_refresh),
              future: ref
                  .read(timeBankServiceProvider)
                  .summaryForProfile(profileId),
              builder: (context, snapshot) {
                final summary = snapshot.data;
                if (summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalancePanel(summary: summary),
                    const SizedBox(height: HabitarSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _grant(profileId, 2, action: 'comenzar'),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('ComenzÃ³'),
                          ),
                        ),
                        const SizedBox(width: HabitarSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _grant(profileId, 15,
                                action: 'rutina completa'),
                            icon: const Icon(Icons.task_alt_rounded),
                            label: const Text('CompletÃ³'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HabitarSpacing.sm),
                    FilledButton.icon(
                      onPressed: summary.availableMinutes <= 0
                          ? null
                          : () => _use(profileId, 5),
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('Registrar uso de 5 min'),
                    ),
                    const SizedBox(height: HabitarSpacing.lg),
                    Text('Historial',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: HabitarSpacing.sm),
                    if (summary.benefits.isEmpty)
                      const EmptyState(
                        icon: Icons.celebration_outlined,
                        title: 'AÃºn no hay beneficios',
                        message:
                            'PodÃ©s acreditar minutos por empezar, pedir ayuda o completar una versiÃ³n posible.',
                      )
                    else
                      for (final benefit in summary.benefits)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.schedule_rounded,
                                color: HabitarColors.primaryGreen),
                            title: Text(benefit.description),
                            subtitle: Text(
                              '${benefit.minutesEarned} min ganados Â· ${benefit.minutesUsed} min usados',
                            ),
                            trailing: Text(
                              '${benefit.balanceMinutes} min',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _grant(String profileId, int minutes,
      {String action = 'versiÃ³n mÃ­nima'}) async {
    final key =
        'manual-$profileId-$action-${DateTime.now().toIso8601String().substring(0, 10)}';
    await ref.read(timeBankServiceProvider).grantTime(
          GrantTimeBenefitInput(
            profileId: profileId,
            description: '$minutes minutos por $action',
            minutes: minutes,
            idempotencyKey: key,
            sourceAction: action,
            dailyLimitMinutes: 30,
          ),
        );
    if (mounted) {
      setState(() => _refresh += 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se acreditaron $minutes minutos.')),
      );
    }
  }

  Future<void> _use(String profileId, int minutes) async {
    await ref.read(timeBankServiceProvider).useMinutes(
          profileId: profileId,
          minutes: minutes,
          approvedByAdultId: ref.read(currentFamilyIdProvider),
        );
    if (mounted) {
      setState(() => _refresh += 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se registrÃ³ el uso de $minutes minutos.')),
      );
    }
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.summary});

  final TimeBankSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HabitarColors.sunlit,
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banco de tiempo digital',
              style: TextStyle(
                color: HabitarColors.deepGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: HabitarSpacing.sm),
            Text(
              '${summary.availableMinutes} min disponibles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: HabitarSpacing.sm),
            Text('${summary.usedMinutes} min usados con aprobaciÃ³n adulta.'),
          ],
        ),
      ),
    );
  }
}
