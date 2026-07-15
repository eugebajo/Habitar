import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';

import '../../dependencies.dart';

class WearablesScreen extends ConsumerStatefulWidget {
  const WearablesScreen({super.key});

  @override
  ConsumerState<WearablesScreen> createState() => _WearablesScreenState();
}

class _WearablesScreenState extends ConsumerState<WearablesScreen> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    final selectedPlatform = ref.watch(selectedWearablePlatformProvider);
    final service = ref.watch(wearableServiceProvider);
    final capabilities = service.capabilitiesFor(selectedPlatform);
    final gateway = ref.watch(wearableGatewayRepositoryProvider);
    final snapshot = gateway.snapshotFor(selectedPlatform);

    return Scaffold(
      appBar: AppBar(title: const Text('Wearables')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HabitarSpacing.lg),
          children: [
            Text('Preparacion por plataforma',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: HabitarSpacing.md),
            SegmentedButton<WearablePlatform>(
              segments: const [
                ButtonSegment(
                    value: WearablePlatform.watchOS, label: Text('watchOS')),
                ButtonSegment(
                    value: WearablePlatform.wearOS, label: Text('Wear OS')),
              ],
              selected: {selectedPlatform},
              onSelectionChanged: (selection) => ref
                  .read(selectedWearablePlatformProvider.notifier)
                  .state = selection.first,
            ),
            const SizedBox(height: HabitarSpacing.md),
            _CapabilityCard(capabilities: capabilities),
            const SizedBox(height: HabitarSpacing.md),
            FilledButton(
                onPressed: () => _publish(selectedPlatform),
                child: const Text('Publicar rutina activa')),
            if (_message != null) ...[
              const SizedBox(height: HabitarSpacing.md),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(HabitarSpacing.md),
                      child: Text(_message!))),
            ],
            const SizedBox(height: HabitarSpacing.lg),
            Text('Ultimo snapshot',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: HabitarSpacing.md),
            if (snapshot == null)
              const Text('Todavia no hay una rutina publicada para el reloj.')
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(HabitarSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(snapshot.routineTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Ahora: ${snapshot.currentStepTitle}'),
                      Text('Despues: ${snapshot.nextStepTitle}'),
                      Text('Minutos restantes: ${snapshot.remainingMinutes}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _publish(WearablePlatform platform) async {
    final sessionId = ref.read(currentRoutineSessionIdProvider);
    final profileId = ref.read(currentProfileIdProvider);
    final sessionRepository = ref.read(routineSessionRepositoryProvider);
    final session = sessionId != null
        ? await sessionRepository.byId(sessionId)
        : profileId != null
            ? await sessionRepository.activeSessionForProfile(profileId)
            : null;

    if (session == null) {
      setState(() => _message = 'Primero crea o inicia una rutina guiada.');
      return;
    }

    final snapshot = await ref
        .read(wearableServiceProvider)
        .publishRoutineSession(platform, session);
    setState(() => _message =
        'Snapshot preparado para ${platform.name}: ${snapshot.currentStepTitle}.');
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.capabilities});

  final WearableCapabilitySet capabilities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HabitarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transportes', style: Theme.of(context).textTheme.titleMedium),
            for (final transport in capabilities.transports)
              Text('- ${transport.name}'),
            const SizedBox(height: HabitarSpacing.md),
            Text('Acciones rapidas',
                style: Theme.of(context).textTheme.titleMedium),
            for (final action in capabilities.quickActions)
              Text('- ${action.name}'),
            const SizedBox(height: HabitarSpacing.md),
            Text('Haptica: ${capabilities.supportsHaptics ? 'si' : 'no'}'),
            Text(
                'Tile/complicacion: ${capabilities.supportsTileOrComplication ? 'si' : 'no'}'),
          ],
        ),
      ),
    );
  }
}
