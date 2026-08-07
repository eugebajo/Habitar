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
  var _vibration = true;
  var _sound = true;
  var _watch = true;

  @override
  Widget build(BuildContext context) {
    final selectedPlatform = ref.watch(selectedWearablePlatformProvider);
    final service = ref.watch(wearableServiceProvider);
    final capabilities = service.capabilitiesFor(selectedPlatform);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos')),
      body: HabitarPage(
        maxWidth: 720,
        children: [
          Row(children: [
            Expanded(
                child: Text('Dispositivos',
                    style: Theme.of(context).textTheme.displaySmall)),
            const HabitarPill(label: 'Tomi', icon: Icons.face_rounded),
          ]),
          const SizedBox(height: 18),
          HabitarCard(
            color: HabitarColors.surfaceMist,
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Conectá los avisos\nde Tomi',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    const Text(
                        'Recibí recordatorios y rutinas en los dispositivos que acompañan su día.'),
                  ])),
              const SizedBox(
                  width: 140,
                  height: 150,
                  child: HabitarSoftIllustration(label: 'watch')),
            ]),
          ),
          const SizedBox(height: 18),
          _DeviceCard(
              title: 'Teléfono de Tomi',
              status: 'Conectado',
              icon: Icons.smartphone_rounded,
              connected: true,
              children: [
                _SwitchRow(
                    label: 'Vibración',
                    value: _vibration,
                    onChanged: (value) => setState(() => _vibration = value)),
                _SwitchRow(
                    label: 'Sonido',
                    value: _sound,
                    onChanged: (value) => setState(() => _sound = value)),
              ]),
          const SizedBox(height: 12),
          _DeviceCard(
              title: 'Smartwatch',
              status: 'No conectado',
              icon: Icons.watch_rounded,
              connected: false,
              trailing: OutlinedButton(
                  onPressed: () {}, child: const Text('Conectar dispositivo'))),
          const SizedBox(height: 12),
          const _DeviceCard(
              title: 'Teléfono del adulto',
              status: 'Conectado',
              icon: Icons.phone_android_rounded,
              connected: true),
          const SizedBox(height: 22),
          Text('Recordatorios', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          HabitarCard(
            child: Column(children: [
              _SwitchTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Enviar al smartwatch',
                  value: _watch,
                  onChanged: (value) => setState(() => _watch = value)),
              _SwitchTile(
                  icon: Icons.vibration_rounded,
                  label: 'Vibración suave',
                  value: _vibration,
                  onChanged: (value) => setState(() => _vibration = value)),
              _SwitchTile(
                  icon: Icons.volume_down_outlined,
                  label: 'Sonido breve',
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value)),
            ]),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          HabitarConversationCard(
            title: 'Compatibilidad',
            body:
                'Los avisos en smartwatch dependen de la compatibilidad del dispositivo y de su configuración.',
            color: HabitarColors.surfaceMist,
            leading: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.info_outline_rounded,
                    color: HabitarColors.deepGreen)),
          ),
          _CapabilityCard(capabilities: capabilities),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: () => _publish(selectedPlatform),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Probar recordatorio')),
          if (_message != null) ...[
            const SizedBox(height: HabitarSpacing.md),
            HabitarConversationCard(
                title: 'Último aviso',
                body: _message!,
                color: HabitarColors.surfaceWarm),
          ],
        ],
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
      setState(() => _message = 'Primero creá o iniciá una rutina guiada.');
      return;
    }

    final snapshot = await ref
        .read(wearableServiceProvider)
        .publishRoutineSession(platform, session);
    setState(() => _message =
        'Snapshot preparado para ${platform.name}: ${snapshot.currentStepTitle}.');
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard(
      {required this.title,
      required this.status,
      required this.icon,
      required this.connected,
      this.children = const [],
      this.trailing});
  final String title;
  final String status;
  final IconData icon;
  final bool connected;
  final List<Widget> children;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => HabitarCard(
        child: Column(children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: HabitarColors.surfaceMist,
                child: Icon(icon, color: HabitarColors.deepGreen)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Row(children: [
                    CircleAvatar(
                        radius: 5,
                        backgroundColor: connected
                            ? HabitarColors.primaryGreen
                            : HabitarColors.warmGold),
                    const SizedBox(width: 8),
                    Text(status,
                        style: TextStyle(
                            color: connected
                                ? HabitarColors.primaryGreen
                                : HabitarColors.ink))
                  ])
                ])),
            if (trailing != null)
              trailing!
            else
              const Icon(Icons.chevron_right_rounded),
          ]),
          if (children.isNotEmpty) ...[
            const Divider(height: 24, color: HabitarColors.line),
            Row(
                children: children
                    .map((child) => Expanded(child: child))
                    .toList(growable: false)),
          ],
        ]),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label),
        const SizedBox(width: 10),
        Switch(value: value, onChanged: onChanged)
      ]);
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: CircleAvatar(
            backgroundColor: HabitarColors.surfaceWarm,
            child: Icon(icon, color: HabitarColors.deepGreen)),
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.capabilities});

  final WearableCapabilitySet capabilities;

  @override
  Widget build(BuildContext context) {
    return HabitarConversationCard(
      title: 'Módulos nativos preparados',
      body:
          'Acciones rápidas: ${capabilities.quickActions.map((action) => action.name).join(', ')}. H?ptica: ${capabilities.supportsHaptics ? 'sí' : 'no'}.',
      color: HabitarColors.card,
    );
  }
}
